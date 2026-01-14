import {GoogleGenAI} from "@google/genai";
import dotenv from 'dotenv';

dotenv.config();

// @ts-ignore
const ai = new GoogleGenAI({apiKey: process.env.GEMINI_API_KEY});

async function listModels() {
    try {
        console.log("Fetching available models...");
        // This lists all models your API key can access
        const response = await ai.models.list();

        console.log("\n--- AVAILABLE MODELS ---");
        // console.log(JSON.stringify(response, null, 2));
        (response as unknown as { pageInternal: any[] }).pageInternal.forEach((model: any) => {
            // Filter for "generateContent" models only
            if (model.supportedActions?.includes("generateContent")) {
                console.log(`Name: ${model.name}`);
                console.log(`ID:   ${model.name.replace('models/', '')}`); // This is the string you need
                console.log(`-------------------------`);
            }
        });
    } catch (error) {
        console.error("Error listing models:", error);
    }
}

listModels();