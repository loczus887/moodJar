import express, {type Request, type Response, type NextFunction} from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {GoogleGenAI} from "@google/genai";

// Load environment variables immediately
dotenv.config();

// --- CONFIGURATION & CONSTANTS ---
const PORT = process.env.PORT || 3000;
// Default to a stable model if specific env var is missing
const MODEL_NAME = process.env.GEMINI_MODEL || "gemini-2.5-flash";
if (!process.env.GEMINI_MODEL) {
    console.warn(`[!] GEMINI_MODEL is not defined. Using default: ${MODEL_NAME}`)
}

// --- SETUP ---
const app = express();
app.use(express.json());
app.use(cors());

// Validate API Key presence at startup to fail fast
const apiKey = process.env.GEMINI_API_KEY;
if (!apiKey) {
    console.error("[FATAL] GEMINI_API_KEY is missing in environment variables.");
    process.exit(1);
}

if (!process.env.GEMINI_MODEL) {
    console.warn(`[WARN] GEMINI_MODEL not defined. Defaulting to: ${MODEL_NAME}`);
}

const ai = new GoogleGenAI({apiKey: apiKey});
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// --- ERROR HANDLING MIDDLEWARE ---
/**
 * Global error handler to ensure consistent JSON responses.
 * Parses backend errors to prevent leaking raw stack traces or malformed strings to the client.
 */
const errorHandler = (err: any, req: Request, res: Response, next: NextFunction) => {
    console.error(`[ERROR] Processing failed: ${err.message}`);

    // Attempt to parse hidden JSON in error messages (common in Google SDKs)
    let parsedDetails = null;
    try {
        if (err.message && err.message.trim().startsWith('{')) {
            parsedDetails = JSON.parse(err.message);
        }
    } catch (e) { /* Ignore parsing error, because if so, then it's a big error that the user should not see */
    }

    const statusCode = err.status || 500;

    res.status(statusCode).json({
        success: false,
        error: {
            message: parsedDetails?.message || err.message || "An unexpected error occurred.",
            code: parsedDetails?.code || err.code || "INTERNAL_SERVER_ERROR",
        }
    });
};

// --- HELPER FUNCTIONS ---

/**
 * loads the system prompt from disk.
 * kept synchronous to ensure prompt is available before processing requests.
 */
const getBasePrompt = (): string => {
    try {
        return fs.readFileSync(path.join(__dirname, 'system-prompt.txt'), 'utf-8');
    } catch (error) {
        console.error("[ERROR] Critical: system-prompt.txt not found.");
        throw new Error("System prompt configuration is missing.");
    }
};

/**
 * dynamic prompt builder.
 * reduces token usage and latency by only requesting fields the client actually needs.
 */
const buildSpecificInstructions = (options: any): string => {
    const instructions = [];
    instructions.push("\n### OUTPUT REQUIREMENTS:");

    if (options.daily_text) {
        instructions.push("- Field 'daily_text': Generate an inspiring summary.");
    }
    if (options.mood_sentences) {
        instructions.push("- Field 'mood_sentences': Generate a map of id -> insight phrase.");
    }
    if (options.memories) {
        instructions.push("- Field 'final_memories': Consolidate existing_memories and new_diaries into a single authoritative list.");
    }

    return instructions.join("\n");
};

/**
 * validates the request payload structure.
 * ensures strictly typed inputs to prevent wasted API calls.
 */
const validateRequest = (body: any) => {
    if (!body.diaries || !Array.isArray(body.diaries) || body.diaries.length === 0) {
        throw {status: 400, message: "Field 'diaries' must be a non-empty array."};
    }

    if (body.memories && !Array.isArray(body.memories)) {
        throw {status: 400, message: "Field 'memories' must be an array."};
    }

    // Sanitize options
    const options = body.options || {};
    return {
        daily_text: options.daily_text !== false,    // Default true
        mood_sentences: options.mood_sentences !== false, // Default true
        memories: options.memories !== false         // Default true
    };
};

// --- ROUTES ---

app.post('/api/analyze', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        // First, validate the request body
        const config = validateRequest(req.body);
        const {diaries, memories} = req.body;

        // Prepare the context with the base prompt and the task instructions
        const basePrompt = getBasePrompt();
        const taskInstructions = buildSpecificInstructions(config);

        const promptData = {
            existing_memories: memories || [],
            new_diaries: diaries
        };

        // Build-up the payload that will be given to the model
        const contents = [
            {
                role: "user",
                parts: [
                    {text: basePrompt},
                    {text: taskInstructions},
                    {text: "\n\n### CONTEXT DATA:\n"},
                    {text: JSON.stringify(promptData, null, 2)}
                ]
            }
        ];

        console.log(`[INFO] Request received. Diaries: ${diaries.length}, Memories: ${memories?.length || 0}. Model: ${MODEL_NAME}`);

        // Call gemini api
        const response = await ai.models.generateContent({
            model: MODEL_NAME,
            contents: contents,
            config: {
                responseMimeType: "application/json",
            }
        });

        const text = response?.text;
        if (!text) throw new Error("Received empty response from AI provider.");

        const jsonResponse = JSON.parse(text);

        // Last check if the AI have gone rogue
        if (config.memories && !Array.isArray(jsonResponse.final_memories)) {
            console.warn("[WARN] AI did not return 'final_memories' array despite request.");
        }

        res.json({
            success: true,
            data: jsonResponse,
        });

    } catch (error) {
        next(error);
    }
});

app.get('/health', (_req, res) => {
    res.status(200).send('OK');
});

// IMPORTANT Register this middleware last at all cost, ALWAYS
app.use(errorHandler);

app.listen(PORT, () => {
    console.log(`[INFO] Server running on http://localhost:${PORT}`);
});