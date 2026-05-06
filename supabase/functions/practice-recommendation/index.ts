import OpenAI from "openai"

const openai = new OpenAI({
  apiKey: Deno.env.get("OPENAI_API_KEY")!
})

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 })
  }

  try {
    const body = await req.json() as PracticeRecommendationRequest

    if (!isValidRequest(body)) {
      return jsonResponse({ error: "Invalid payload" }, 400)
    }

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      temperature: 0.4,
      messages: [
        {
          role: "system",
          content: systemPrompt
        },
        {
          role: "user",
          content: JSON.stringify(body)
        }
      ],
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "practice_recommendation",
          strict: true,
          schema: {
            type: "object",
            properties: {
              selected_id: {
                type: "string",
                description: "The id of the selected candidate from the provided shortlist."
              },
              title: {
                type: "string",
                description: "Short notification title, 45 characters or fewer."
              },
              body: {
                type: "string",
                description: "Friendly notification body, 90 characters or fewer."
              }
            },
            required: ["selected_id", "title", "body"],
            additionalProperties: false
          }
        }
      }
    })

    const content = completion.choices[0].message.content

    if (!content) {
      return jsonResponse({ error: "Recommendation generation failed" }, 500)
    }

    const copy = JSON.parse(content) as PracticeRecommendationResponse

    if (!body.candidates.some((candidate) => candidate.id === copy.selected_id)) {
      return jsonResponse({ error: "Selected candidate was not in the shortlist" }, 500)
    }

    return jsonResponse(copy, 200)
  } catch (err) {
    console.error("Practice recommendation error:", err)
    return jsonResponse({ error: "Recommendation generation failed" }, 500)
  }
})

const systemPrompt = `
You write short, direct practice recommendations for an Indian classical music practice app.

The app has already ranked practice areas deterministically.
Your job is to choose one area from the provided shortlist and phrase that recommendation.

Rules:
- Choose exactly one candidate from the provided shortlist.
- Return the selected candidate's exact id as selected_id.
- Prefer higher-ranked candidates unless a nearby lower-ranked candidate makes the recommendation feel less repetitive or more natural.
- Include the exact practice area name in either the title or body.
- Do not derive new insights, scores, urgency, or conclusions.
- Do not mention GPT, algorithms, metrics, data, ratings, or notifications.
- Keep the tone matter-of-fact and specific.
- Avoid motivational filler, coaching cliches, and AI-ish encouragement.
- Avoid vague phrases like "a little time", "calm attention", "keep it present", and "good place to begin".
- Do not use guilt, pressure, exaggeration, exclamation marks, or phrases like "you should".
- Prefer concrete wording like "Work on <area> today" or "Spend 10 minutes on <area>".
- Return one title and one body only.
- Title must be 45 characters or fewer.
- Body must be 90 characters or fewer.
`

function isValidRequest(
  body: PracticeRecommendationRequest
): body is PracticeRecommendationRequest {
  return Boolean(
    body &&
      Array.isArray(body.candidates) &&
      body.candidates.length > 0 &&
      body.candidates.every(isValidCandidate)
  )
}

function isValidCandidate(
  candidate: PracticeRecommendationCandidate
): candidate is PracticeRecommendationCandidate {
  return Boolean(
    candidate &&
      typeof candidate.id === "string" &&
      candidate.id.trim().length > 0 &&
      typeof candidate.area_name === "string" &&
      candidate.area_name.trim().length > 0 &&
      typeof candidate.rank === "number" &&
      typeof candidate.priority_score === "number" &&
      typeof candidate.primary_reason === "string" &&
      Array.isArray(candidate.supporting_reasons)
  )
}

function jsonResponse(
  body: Record<string, unknown>,
  status: number
): Response {
  return new Response(JSON.stringify(body), {
    headers: { "Content-Type": "application/json" },
    status
  })
}

export type PracticeRecommendationRequest = {
  candidates: PracticeRecommendationCandidate[]
}

type PracticeRecommendationCandidate = {
  id: string
  area_name: string
  rank: number
  priority_score: number
  primary_reason: PracticeSuggestionReasonPayload
  supporting_reasons: PracticeSuggestionReasonPayload[]
}

type PracticeSuggestionReasonPayload =
  | "noRatingsYet"
  | "neglected"
  | "dueForPractice"
  | "concertDrop"
  | "decliningTrend"
  | "lowerRecentScore"
  | "highVolatility"
  | "steadyMaintenance"

type PracticeRecommendationResponse = {
  selected_id: string
  title: string
  body: string
}
