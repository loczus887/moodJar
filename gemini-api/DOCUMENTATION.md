# Gemini API Documentation

This API provides an interface to analyze user diaries and memories using Google's Gemini AI. It is designed to generate summaries, mood insights, and consolidate memories.

## Base URL

By default, the server runs on:
`http://localhost:3000`

(Port can be configured via the `PORT` environment variable).

---

## Endpoints

### 1. Analyze Diaries & Memories

**Endpoint:** `POST /api/analyze`

**Description:**
Sends user diaries and existing memories to the Gemini AI model to generate a daily summary, mood insights, and an updated list of memories.

#### Request Body (JSON)

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `diaries` | `Array` | **Yes** | A non-empty array of diary entries to analyze. |
| `memories` | `Array` | No | An array of existing memories to be consolidated with new information. Defaults to `[]`. |
| `options` | `Object` | No | Configuration object to enable/disable specific output fields. |

**Options Object:**

| Field | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `daily_text` | `boolean` | `true` | If `true`, generates an inspiring summary (`daily_text`). |
| `mood_sentences` | `boolean` | `true` | If `true`, generates a map of mood insights (`mood_sentences`). |
| `memories` | `boolean` | `true` | If `true`, consolidates and returns the updated list of memories (`final_memories`). |

#### Example Request

```json
{
  "diaries": [
    {
      "id": "1",
      "content": "Today was a productive day. I finished my project.",
      "date": "2023-10-27"
    }
  ],
  "memories": [
    {
      "id": "m1",
      "content": "User likes coding."
    }
  ],
  "options": {
    "daily_text": true,
    "mood_sentences": true,
    "memories": true
  }
}
```

#### Response

Returns a JSON object containing the AI-generated analysis.

**Success Response (200 OK):**

```json
{
  "success": true,
  "data": {
    "daily_text": "You had a very productive day completing your project...",
    "mood_sentences": {
      "1": "Feeling accomplished and productive."
    },
    "final_memories": [
      { "id": "m1", "content": "User likes coding." },
      { "id": "m2", "content": "User feels good when finishing projects." }
    ]
  }
}
```

**Error Response:**

```json
{
  "success": false,
  "error": {
    "message": "Field 'diaries' must be a non-empty array.",
    "code": "INTERNAL_SERVER_ERROR"
  }
}
```

---

### 2. Health Check

**Endpoint:** `GET /health`

**Description:**
Simple health check endpoint to verify if the server is running.

#### Response

**Status:** `200 OK`
**Body:** `OK`
