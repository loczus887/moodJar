import express, {Request, Response} from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import {GoogleGenerativeAI} from '@google/generative-ai';

// 1. Load environment variables
dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

// 2. Middleware
app.use(express.json()); // To parse JSON bodies
app.use(cors());         // To allow requests from other domains

// 3. Initialize Gemini Client
const apiKey = process.env.GEMINI_API_KEY;
if (!apiKey) {
    console.error("Error: GEMINI_API_KEY is missing in .env file");
    process.exit(1);
}

const genAI = new GoogleGenerativeAI(apiKey);
// Using the 'gemini-1.5-flash' model for speed and efficiency
const model = genAI.getGenerativeModel({model: "gemini-1.5-flash"});

// 4. Define the Chat Endpoint
app.post('/api/chat', async (req: Request, res: Response): Promise<any> => {
    try {
        const {prompt} = req.body;

        if (!prompt) {
            return res.status(400).json({error: 'Prompt is required'});
        }

        // Call Gemini API
        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();

        // Send back the result
        return res.json({
            success: true,
            data: text,
        });

    } catch (error: any) {
        console.error('Error generating content:', error);
        return res.status(500).json({
            success: false,
            error: error.message || 'Internal Server Error',
        });
    }
});

// 5. Start the Server
app.listen(port, () => {
    console.log(`Server is running at http://localhost:${port}`);
});