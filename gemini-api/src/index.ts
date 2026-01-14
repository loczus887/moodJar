import express, {type Request, type Response} from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import fs from 'node:fs';
import path from 'node:path';
// 1. New Import
import {GoogleGenAI} from "@google/genai";

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());
app.use(cors());

const apiKey = process.env.GEMINI_API_KEY;
if (!apiKey) {
    console.error("Error: GEMINI_API_KEY is missing in .env file");
    process.exit(1);
}

// 2. New Client Initialization
const ai = new GoogleGenAI({apiKey: apiKey});

const getSystemPrompt = () => {
    try {
        const promptPath = path.join(__dirname, 'system-prompt.txt');
        return fs.readFileSync(promptPath, 'utf-8');
    } catch (error) {
        console.error("Error reading system-prompt.txt", error);
        return "";
    }
};

/**
 * Helper to retry calls if 503 Overloaded
 */
async function generateContentWithRetry(contents: any, retries = 3, delay = 1000) {
    for (let i = 0; i < retries; i++) {
        try {
            // 3. New Call Syntax
            const response = await ai.models.generateContent({
                model: "gemini-2.5-flash", // Or "gemini-2.0-flash-exp"
                contents: contents,
                config: {
                    responseMimeType: "application/json",
                }
            });
            return response;
        } catch (error: any) {
            const isOverloaded = error.message?.includes('503') || error.message?.includes('overloaded');
            if (isOverloaded && i < retries - 1) {
                console.warn(`Gemini is overloaded. Retrying in ${delay}ms...`);
                await new Promise(res => setTimeout(res, delay));
                delay *= 2;
            } else {
                throw error;
            }
        }
    }
}

app.post('/api/analyze', async (req: Request, res: Response): Promise<any> => {
    try {
        const {diaries} = req.body;

        if (!diaries || !Array.isArray(diaries) || diaries.length === 0) {
            return res.status(400).json({error: 'A list of diaries is required'});
        }

        const baseSystemInstruction = getSystemPrompt();

        // 4. Constructing the Prompt parts
        // The new SDK prefers an array of parts for text + data
        const contents = [
            {
                role: "user",
                parts: [
                    {text: baseSystemInstruction},
                    {text: "\n\nHere is the user data:\n"},
                    {text: JSON.stringify(diaries, null, 2)}
                ]
            }
        ];

        // Call Gemini with our retry wrapper
        const response = await generateContentWithRetry(contents);

        // 5. Getting the text
        // The new SDK simplifies this. If responseMimeType is JSON,
        // response.text often returns the stringified JSON.
        const text = response?.text;

        if (!text) {
            throw new Error("Empty response from Gemini");
        }

        // Parse to ensure valid JSON before sending to Flutter
        const jsonResponse = JSON.parse(text);

        return res.json({
            success: true,
            data: jsonResponse,
        });

    } catch (error: any) {
        console.error('Error processing diaries:', error);
        return res.status(500).json({
            success: false,
            error: error.message || 'Internal Server Error',
        });
    }
});

app.listen(port, () => {
    console.log(`Server is running at http://localhost:${port}`);
});