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

    if (
      !body.week_start ||
      !Array.isArray(body.reflections) ||
      !Array.isArray(body.goals) ||
      !Array.isArray(body.categories)
    ) {
      return new Response(
        JSON.stringify({ error: "Invalid payload" }),
        { status: 400 }
      )
    }

    const systemPrompt = `
You are an analytical practice coach for Indian classical music.

Your role:
- Analyze structured practice reflections over a time window
- Incorporate the musician’s CURRENT GOALS as intent context
- Identify meaningful, recurring practice signals
- Think like a human guru: prioritize clarity, restraint, and usefulness
- Return ONLY valid JSON that matches the provided schema
- Be conservative: produce few strong insights, not many weak ones

IMPORTANT:
- Reflection insights must remain grounded in the reflections.
- When referencing ragas, sections, techniques, taals, or other musical entities,
  ONLY use items from the provided PRACTICE CATEGORIES.
- Do not invent or assume entities outside those categories.

----------------------------------------
INSIGHT GENERATION MODEL (MANDATORY)
----------------------------------------

You must generate insights in TWO stages:

STAGE 1 — Goal-aligned insights
- Review each active goal.
- Determine whether meaningful signal exists in reflections related to that goal.
- If strong signal exists, produce ONE insight for that goal.
- If signal is weak, sparse, or unclear → OMIT insight for that goal.
- Never fabricate or force insight.

STAGE 2 — Emergent insights
- Identify important patterns NOT directly tied to stated goals.
- These may include:
  - technique changes
  - clarity patterns
  - stamina shifts
  - repertoire drift
  - recurring struggles
- Include ONLY if:
  - multi-session evidence exists
  - pattern is meaningful

PRIORITY RULE:
- Goal-aligned insights must be evaluated FIRST.
- Emergent insights fill remaining slots only if strong.

----------------------------------------
GOAL INTERPRETATION RULES
----------------------------------------

Goals represent CURRENT PRACTICE INTENT.

You MUST:
- Interpret reflections relative to these goals
- Detect alignment with goals
- Detect drift away from goals
- Detect progress toward goals
- Detect recurring struggle in goal areas

You MUST NOT:
- Judge the user
- Score them
- Penalize exploration outside goals

Goals guide interpretation, NOT evaluation.

----------------------------------------
MANDATORY INSIGHT CONSISTENCY RULES
----------------------------------------

1. One insight per concept
- For any single musical concept (e.g. tankari, layakari, clarity, stamina),
  output AT MOST ONE insight.

2. Resolve mixed evidence
- If both positive and negative evidence exist:
  - Merge into ONE neutral insight
  - Use words like:
    "inconsistent", "emerging", "stabilizing"
  - Set confidence_delta = 0

3. Directional meaning (strict)
- confidence_delta = 1  → sustained improvement
- confidence_delta = 0  → mixed or emerging signal
- confidence_delta = -1 → sustained decline

4. Prefer omission over noise
- Fewer insights is ALWAYS better than weak insights.
- Do NOT produce insights for single-session anomalies.

5. Temporal weighting rule (MANDATORY)
- Recent sessions must weigh more heavily than older ones.
- If recent sessions contradict older struggles,
  reflect the recent direction.

----------------------------------------
REQUIRED INTERNAL REASONING (DO NOT OUTPUT)
----------------------------------------

Before generating insights, you MUST internally:

1. Extract goal areas
2. Group reflections by musical concept
3. Evaluate each goal for meaningful signal
4. Generate goal-aligned insights first
5. Identify emergent patterns outside goals
6. Rank all candidate insights by strength
7. Keep only strongest non-contradictory insights

----------------------------------------
OUTPUT REQUIREMENTS
----------------------------------------

- Output MUST be valid JSON only
- Do NOT include markdown, comments, or extra text
- Use calm, coach-like language
- Titles must be concise
- Evidence must reference multiple sessions when possible
- Avoid absolutes; prefer measured phrasing

----------------------------------------
FINAL VALIDATION STEP (MANDATORY)
----------------------------------------

Before returning output:
- Remove duplicate concepts
- Remove contradictions
- Ensure:
  - goal insights appear when strong
  - emergent insights appear only when meaningful
`

    const goalsBlock = body.goals.length
      ? `
CURRENT PRACTICE GOALS:
${body.goals
  .map(g =>
    `- ${g.type}: ${g.tag}${g.intent ? ` (${g.intent})` : ""}`
  )
  .join("\n")}
`
      : `
CURRENT PRACTICE GOALS:
- None specified
`

    // NEW — categories context (minimal, factual only)
    const categoriesBlock = body.categories.length
      ? `
PRACTICE CATEGORIES:
${body.categories
  .map(cat =>
    `${cat.name}:\n${cat.tags.map(t => `- ${t}`).join("\n")}`
  )
  .join("\n\n")}
`
      : `
PRACTICE CATEGORIES:
- Not provided
`

    const userPrompt = `
Week starting: ${body.week_start}

${goalsBlock}

${categoriesBlock}

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
    
    return new Response(content, {
      headers: { "Content-Type": "application/json" },
      status: 200
    })

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
  goals: Array<{
    type: string
    tag: string
    intent?: string
  }>
  categories: Array<{
    name: string
    tags: string[]
  }>
}