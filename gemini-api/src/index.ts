import express, {type Request, type Response} from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import fs from 'node:fs';
import path from 'node:path';
import {GoogleGenerativeAI} from '@google/generative-ai';
import {fileURLToPath} from 'url';

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

const genAI = new GoogleGenerativeAI(apiKey);
const model = genAI.getGenerativeModel({
    model: "gemini-2.0-flash-lite"
    // generationConfig: {
    //     responseMimeType: "application/json"
    // }
});

const getSystemPrompt = () => {
    try {
        const __filename = fileURLToPath(import.meta.url);
        const __dirname = path.dirname(__filename);
        const promptPath = path.join(__dirname, 'system-prompt.txt');
        console.log(promptPath)
        return fs.readFileSync(promptPath, 'utf-8');
    } catch (error) {
        console.error("Error reading system-prompt.txt", error);
        return "";
    }
};

app.get("/health", (req: Request, res: Response) => {
    res.status(200).send("OK");
});

app.post('/api/analyze', async (req: Request, res: Response): Promise<any> => {
    try {
        // Expected format: { diaries: [{ id, diary, emotion, date }] }
        const {diaries} = req.body;

        if (!diaries || !Array.isArray(diaries) || diaries.length === 0) {
            return res.status(400).json({error: 'A list of diaries is required'});
        }

        // ead the latest version of your prompt file
        // Reading it here ensures that if you edit the text file,
        // the very next request uses the new version without restarting node.
        const baseSystemInstruction = getSystemPrompt();

        if (!baseSystemInstruction) {
            return res.status(500).json({error: 'System prompt file missing or empty'});
        }

        // We combine your instructions with the actual data
        const finalPrompt = `${baseSystemInstruction}\n\nHere is the user data:\n${JSON.stringify(diaries, null, 2)}`;

        const result = await model.generateContent(finalPrompt);
        const response = result.response;
        const text = response.text();

        // Since we enforced JSON mode, 'text' is a valid JSON string.
        // We parse it here to ensure it is valid before sending to Flutter.
        try {
            console.log(text)
            const jsonResponse = JSON.parse(text);

            return res.json({
                success: true,
                data: jsonResponse,
            });
        } catch (jsonError) {
            console.error("Error parsing JSON response from Gemini:", jsonError);
            return res.status(500).json({
                success: false,
                error: "Invalid JSON response from AI model",
                rawResponse: text,
            });
        }

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