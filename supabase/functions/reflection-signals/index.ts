import OpenAI from "openai"

const openai = new OpenAI({
  apiKey: Deno.env.get("OPENAI_API_KEY")!
})

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 })
  }

  try {
    const body = await req.json() as ReflectionRequest

    if (!body.week_start || !Array.isArray(body.reflections)) {
      return new Response(
        JSON.stringify({ error: "Invalid payload" }),
        { status: 400 }
      )
    }

    const systemPrompt = `
      You are an analytical practice coach for Indian classical music.

      Your role:
      - Analyze structured practice reflections over a time window
      - Identify meaningful, recurring practice signals
      - Think like a human guru: prioritize clarity, restraint, and usefulness
      - Return ONLY valid JSON that matches the provided schema
      - Be conservative: produce few strong insights, not many weak ones

      ----------------------------------------
      MANDATORY INSIGHT CONSISTENCY RULES
      ----------------------------------------

      1. One insight per concept
      - For any single musical concept (e.g. tankari, layakari, clarity, stamina),
        output AT MOST ONE insight.
      - You must NEVER produce contradictory insights about the same concept.

      2. Resolve mixed evidence
      - If evidence contains both positive and negative examples:
        - Resolve them into a SINGLE aggregated judgment
        - Use neutral or trend language such as:
          "inconsistent", "emerging", "stabilizing"
        - Set confidence_delta = 0
      - If the signal is weak or contradictory, OMIT the insight entirely.

      3. Directional meaning (strict)
      - confidence_delta = 1  → sustained improvement across multiple sessions
      - confidence_delta = 0  → mixed, emerging, or inconsistent signal
      - confidence_delta = -1 → sustained decline across multiple sessions

      4. Prefer omission over noise
      - It is always better to return fewer insights than to return uncertain ones.
      - Do NOT restate obvious facts or single-session anomalies.

      5. Temporal weighting rule (MANDATORY):
      - More recent sessions must be weighted more heavily than older ones.
      - When assessing a skill, prioritize patterns from the latest sessions in the window.
      - Older sessions may provide context, but must not override a clear recent trend.
      - If recent sessions contradict older struggles, the insight should reflect the recent state.
      ----------------------------------------
      REQUIRED INTERNAL REASONING (DO NOT OUTPUT)
      ----------------------------------------

      Before generating insights, you MUST internally:
      1. Group observations by musical concept
      2. Aggregate evidence across all sessions in the window
      3. Decide the dominant direction for each concept:
        - improving
        - declining
        - inconsistent
        - stable
      4. Generate at most ONE insight per concept
      5. Discard concepts with weak or contradictory signals

      ----------------------------------------
      OUTPUT REQUIREMENTS
      ----------------------------------------

      - Output MUST be valid JSON only
      - Do NOT include markdown, comments, or extra text
      - Use calm, coach-like language
      - Titles should be concise and non-redundant
      - Evidence must reference multiple sessions when possible
      - Avoid absolutes; prefer measured phrasing

      ----------------------------------------
      FINAL VALIDATION STEP (MANDATORY)
      ----------------------------------------

      Before returning output:
      - Re-scan all insights
      - If two insights refer to the same concept with opposing sentiment,
        KEEP the stronger one and DELETE the weaker one

    `

    const userPrompt = `
      Week starting: ${body.week_start}
      Practice reflections:
      ${body.reflections.map(r => `- ${r.date}: ${r.notes}`).join("\n")}
    `
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      temperature: 0.2,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt }
      ],
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "reflection_insight",
          strict: true, 
          schema: {
            type: "object",
            properties: {
              items: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    item: { type: "string" },
                    confidence_delta: {
                      type: "number",
                      enum: [-1, 0, 1]
                    },
                    evidence: { type: "string" }
                  },
                  required: ["item", "confidence_delta", "evidence"],
                  additionalProperties: false
                }
              }
            },
            required: ["items"],
            additionalProperties: false
          }
        }
      }
    })

    const content = completion.choices[0].message.content
    
    return new Response(
      content, 
      {
        headers: { "Content-Type": "application/json" },
        status: 200
      }
    )

  } catch (err) {
    console.error("Reflection insight error:", err)
    return new Response(
      JSON.stringify({ error: "Insight generation failed" }),
      { status: 500 }
    )
  }
})

export type ReflectionRequest = {
  week_start: string
  reflections: Array<{
    date: string
    notes: string
    metrics: Record<string, number>
  }>
}