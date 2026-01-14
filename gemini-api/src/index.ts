import express, {type Request, type Response, type NextFunction} from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {GoogleGenAI} from "@google/genai";

dotenv.config();

// --- CONFIGURATION & CONSTANTS ---
const PORT = process.env.PORT || 3000;
const MODEL_NAME = process.env.GEMINI_MODEL || "gemini-2.5-flash";
if (!process.env.GEMINI_MODEL) {
    console.warn(`[!] GEMINI_MODEL is not defined. Using default: ${MODEL_NAME}`)
}

// --- SETUP ---
const app = express();
app.use(express.json());
app.use(cors());

const apiKey = process.env.GEMINI_API_KEY;
if (!apiKey) {
    console.error("[x] GEMINI_API_KEY is missing");
    process.exit(1);
}

const ai = new GoogleGenAI({apiKey: apiKey});
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// --- ERROR HANDLING MIDDLEWARE ---
// This prevents the "ugly big JSON string" responses
const errorHandler = (err: any, req: Request, res: Response, next: NextFunction) => {
    console.error(`[Error] ${err.message}`);

    // Try to parse if the error message is actually a hidden JSON string (Common in Google SDKs)
    let parsedDetails = null;
    try {
        if (err.message && err.message.trim().startsWith('{')) {
            parsedDetails = JSON.parse(err.message);
        }
    } catch (e) { /* Ignore parsing error */
    }

    const statusCode = err.status || 500;

    // Clean response structure
    res.status(statusCode).json({
        success: false,
        error: {
            message: parsedDetails?.message || err.message || "Internal Server Error",
            code: parsedDetails?.code || err.code || "UNKNOWN_ERROR",
            type: err.constructor.name
        }
    });
};

// --- HELPER FUNCTIONS ---

const getBasePrompt = () => {
    try {
        return fs.readFileSync(path.join(__dirname, 'system-prompt.txt'), 'utf-8');
    } catch (error) {
        console.error("Error reading prompt file", error);
        throw new Error("System prompt file missing");
    }
};

/**
 * Builds the text instructions for Gemini based on what the client wants.
 */
const buildSpecificInstructions = (options: any) => {
    let instructions = "\n\n### INSTRUCTIONS FOR THIS REQUEST:\n";

    if (options.daily_text) instructions += "- Generate 'daily_text': An inspiring summary.\n";
    if (options.mood_sentences) instructions += "- Generate 'mood_sentences': A map of diary_id to inspiring phrase.\n";
    if (options.memories) instructions += "- Perform MEMORY MANAGEMENT. Return 'final_memories' list (filter old, add new).\n";

    instructions += "\nOnly include the keys requested above in the JSON output.";
    return instructions;
};

// --- ROUTES ---

app.post('/api/analyze', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const {diaries, memories, options} = req.body;

        // Default options if not provided
        const config = {
            daily_text: options?.daily_text ?? true,
            mood_sentences: options?.mood_sentences ?? true,
            memories: options?.memories ?? true,
        };

        if (!diaries || !Array.isArray(diaries) || diaries.length === 0) {
            throw {status: 400, message: "A list of 'diaries' is required"};
        }

        const basePrompt = getBasePrompt();
        const taskInstructions = buildSpecificInstructions(config);

        // Construct the "Context" payload
        const promptData = {
            existing_memories: memories || [], // Current context
            new_diaries: diaries               // New input
        };

        const contents = [
            {
                role: "user",
                parts: [
                    {text: basePrompt},
                    {text: taskInstructions},
                    {text: "\n\n### DATA TO ANALYZE:\n"},
                    {text: JSON.stringify(promptData, null, 2)}
                ]
            }
        ];

        console.log(`🤖 Sending request to ${MODEL_NAME}...`);

        const response = await ai.models.generateContent({
            model: MODEL_NAME,
            contents: contents,
            config: {
                responseMimeType: "application/json",
            }
        });

        const text = response?.text;
        if (!text) throw new Error("Received empty response from Gemini");

        const jsonResponse = JSON.parse(text);

        res.json({
            success: true,
            data: jsonResponse,
        });

    } catch (error) {
        // Pass to the middleware
        next(error);
    }
});

app.get('/health', (_req, res) => {
    res.send('OK');
});

// Register Error Middleware Last
app.use(errorHandler);

app.listen(PORT, () => {
    console.log(`Server is running at http://localhost:${PORT}`);
});