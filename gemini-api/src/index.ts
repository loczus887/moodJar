import express, {type Request, type Response} from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import {GoogleGenerativeAI} from '@google/generative-ai';

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
const model = genAI.getGenerativeModel({model: "gemini-2.5-flash"});

app.get("/health", (req: Request, res: Response) => {
    res.setHeader('Content-Type', 'text/plain');
    res.status(200);
    res.send("OK");
    res.end();
})

app.post('/api/chat', async (req: Request, res: Response): Promise<any> => {
    try {
        const {prompt} = req.body;

        if (!prompt) {
            return res.status(400).json({error: 'Prompt is required'});
        }

        // Call Gemini API
        const result = await model.generateContent(prompt);
        const response = result.response;
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

app.listen(port, () => {
    console.log(`Server is running at http://localhost:${port}`);
});