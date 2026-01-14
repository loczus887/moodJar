import express, {type Request, type Response, type NextFunction} from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {GoogleGenAI} from "@google/genai";
import {pinoHttp} from 'pino-http';
import {logger} from './logger.js';

dotenv.config();

const PORT = process.env.PORT || 3000;
const MODEL_NAME = process.env.GEMINI_MODEL || "gemini-1.5-flash-002";

const app = express();

app.use(pinoHttp({
    logger,
    autoLogging: false,
    customSuccessMessage: (req, res) => {
        return `Request ${req.id} | ${req.method} ${req.url} | ${res.statusCode} | ${Date.now() - (req as any).startTime}ms`;
    },
    customErrorMessage: (req, res, err) => {
        return `Request ${req.id} | ${req.method} ${req.url} | ${res.statusCode} | FAILED: ${err.message}`;
    }
}));

app.use((req, _res, next) => {
    (req as any).startTime = Date.now();
    next();
});

app.use(express.json());
app.use(cors());

const apiKey = process.env.GEMINI_API_KEY;
if (!apiKey) {
    logger.fatal("GEMINI_API_KEY is missing. Exiting.");
    process.exit(1);
}

const ai = new GoogleGenAI({apiKey: apiKey});
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const errorHandler = (err: any, req: Request, res: Response, next: NextFunction) => {
    const statusCode = err.status || 500;

    req.log.error({err}, "Request failed");

    let parsedDetails = null;
    try {
        if (err.message && err.message.trim().startsWith('{')) {
            parsedDetails = JSON.parse(err.message);
        }
    } catch (e) {
    }

    res.status(statusCode).json({
        success: false,
        error: {
            message: parsedDetails?.message || err.message || "An unexpected error occurred.",
            code: parsedDetails?.code || err.code || "INTERNAL_SERVER_ERROR",
        }
    });
};

const getBasePrompt = (): string => {
    try {
        return fs.readFileSync(path.join(__dirname, 'system-prompt.txt'), 'utf-8');
    } catch (error) {
        logger.error("Critical: system-prompt.txt not found.");
        throw new Error("System prompt configuration is missing.");
    }
};

const buildSpecificInstructions = (options: any): string => {
    const instructions = ["\n### OUTPUT REQUIREMENTS:"];
    if (options.daily_text) instructions.push("- Field 'daily_text': Generate an inspiring summary.");
    if (options.mood_sentences) instructions.push("- Field 'mood_sentences': Generate a map of id -> insight phrase.");
    if (options.memories) instructions.push("- Field 'final_memories': Consolidate existing_memories and new_diaries.");
    return instructions.join("\n");
};

const validateRequest = (body: any) => {
    if (!body.diaries || !Array.isArray(body.diaries) || body.diaries.length === 0) {
        throw {status: 400, message: "Field 'diaries' must be a non-empty array."};
    }
    if (body.memories && !Array.isArray(body.memories)) {
        throw {status: 400, message: "Field 'memories' must be an array."};
    }
    const options = body.options || {};
    return {
        daily_text: options.daily_text !== false,
        mood_sentences: options.mood_sentences !== false,
        memories: options.memories !== false
    };
};

app.post('/api/analyze', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const config = validateRequest(req.body);
        const {diaries, memories} = req.body;

        const basePrompt = getBasePrompt();
        const taskInstructions = buildSpecificInstructions(config);

        const promptData = {
            existing_memories: memories || [],
            new_diaries: diaries
        };

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

        req.log.info({
            diaries: diaries.length,
            memories: memories?.length || 0,
            model: MODEL_NAME
        }, "Analysis Request Processing");

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

app.use(errorHandler);

app.listen(PORT, () => {
    logger.info(`Server running on http://localhost:${PORT}`);
});