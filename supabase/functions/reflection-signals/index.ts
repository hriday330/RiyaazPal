import OpenAI from "openai"

const openai = new OpenAI({
  apiKey: Deno.env.get("OPENAI_API_KEY")!
})

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 })
  }

  try {
    const body = await req.json() as PracticeAreaInsightSummaryRequest

    if (!isValidRequest(body)) {
      return jsonResponse({ error: "Invalid payload" }, 400)
    }

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      temperature: 0.2,
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
          name: "practice_area_summary",
          strict: true,
          schema: {
            type: "object",
            properties: {
              summary: {
                type: "string",
                description: "A concise two-sentence overall overview of the deterministic practice and concert insight payload."
              }
            },
            required: ["summary"],
            additionalProperties: false
          }
        }
      }
    })

    const content = completion.choices[0].message.content

    if (!content) {
      return jsonResponse({ error: "Summary generation failed" }, 500)
    }

    const summary = JSON.parse(content) as PracticeAreaInsightSummaryResponse

    return jsonResponse(summary, 200)
  } catch (err) {
    console.error("Practice area summary error:", err)
    return jsonResponse({ error: "Summary generation failed" }, 500)
  }
})

const systemPrompt = `
You are a concise Indian classical music practice coach.

The app has already computed all practice and concert insights deterministically.
Your job is only to summarize the supplied metrics in natural language as one overall picture across both practice and concerts.

Rules:
- Do not derive new metrics, thresholds, scores, rankings, or conclusions.
- Do not reference notes, tags, reflections, or anything outside the payload.
- Do not write separate practice and concert summaries.
- Synthesize practice progress and concert transfer into one all-encompassing overview.
- Do not give a bullet list.
- Write exactly one or two short sentences.
- Mention at most three practice area names total.
- Keep the tone encouraging, grounded, and brief.
- If the payload has little data, simply say there is not enough rated data yet.
`

function isValidRequest(
  body: PracticeAreaInsightSummaryRequest
): body is PracticeAreaInsightSummaryRequest {
  return Boolean(
    body &&
      typeof body.window_start === "string" &&
      typeof body.window_end === "string" &&
      body.practice &&
      body.concert &&
      Array.isArray(body.practice.areas) &&
      Array.isArray(body.concert.areas)
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

export type PracticeAreaInsightSummaryRequest = {
  window_start: string
  window_end: string
  practice: PracticeInsightPayload
  concert: ConcertInsightPayload
}

type PracticeInsightPayload = {
  active_area_count: number
  rated_area_count: number
  latest_average: number | null
  improving_count: number
  needs_attention_count: number
  areas: PracticeAreaPayload[]
}

type ConcertInsightPayload = {
  concert_count: number
  rated_area_count: number
  latest_average: number | null
  significant_drop_count: number
  concert_lift_count: number
  maintained_count: number
  areas: PracticeAreaPayload[]
}

type PracticeAreaPayload = {
  name: string
  is_active: boolean
  latest_score: number | null
  seven_day_average: number | null
  previous_seven_day_average: number | null
  thirty_day_average: number | null
  trend: "improving" | "declining" | "stable" | "insufficientData"
  rated_session_count: number
  days_since_practiced: number | null
  is_neglected: boolean
  volatility: number | null
  practice: PracticeAreaContextPayload
  concert: PracticeAreaContextPayload
  transfer: PracticeAreaTransferPayload
}

type PracticeAreaContextPayload = {
  latest_score: number | null
  average_score: number | null
  rated_session_count: number
  volatility: number | null
}

type PracticeAreaTransferPayload = {
  practice_average: number | null
  concert_average: number | null
  delta: number | null
  status: "significantDrop" | "concertLift" | "maintained" | "inconclusive" | "insufficientData"
}

type PracticeAreaInsightSummaryResponse = {
  summary: string
}
