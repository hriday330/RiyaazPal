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
      !Array.isArray(body.goals)
    ) {
      return new Response(
        JSON.stringify({ error: "Invalid payload" }),
        { status: 400 }
      )
    }

    // ------------------------------------------------------------
    // STEP 1 — Normalize reflections
    // ------------------------------------------------------------

    const normalizedReflections = body.reflections.map(r => ({
      ...r,
      tagsLower: (r.tags ?? []).map(t => t.toLowerCase())
    }))

    // ------------------------------------------------------------
    // STEP 2 — Deterministic goal → reflection matching via tags
    // ------------------------------------------------------------

    const goalEvidence = body.goals.map(goal => {
      const tagLower = goal.tag.toLowerCase()

      const matching = normalizedReflections.filter(r =>
        r.tagsLower.includes(tagLower)
      )

      return {
        goal,
        reflections: matching
      }
    })

    // ------------------------------------------------------------
    // STEP 3 — Prepare insights array
    // ------------------------------------------------------------

    const insights: InsightItem[] = []

    // ------------------------------------------------------------
    // STEP 4 — Deterministic handling per goal
    // ------------------------------------------------------------

    for (const entry of goalEvidence) {
      const { goal, reflections } = entry

      // --------------------------------------------------------
      // CASE A — No sessions tagged with this goal
      // deterministic neutral insight
      // --------------------------------------------------------

      if (reflections.length === 0) {
        insights.push({
          item: `No sessions tagged with ${goal.tag} were found in this period.`,
          confidence_delta: 0,
          evidence: `No practice sessions were explicitly tagged with ${goal.tag}.`
        })
        continue
      }

      function extractGoalContexts(notes: string, goalTag: string, windowSize = 80): string[] {
        const lowerNotes = notes.toLowerCase()
        const lowerTag = goalTag.toLowerCase()

        const contexts: string[] = []

        let index = 0
        while ((index = lowerNotes.indexOf(lowerTag, index)) !== -1) {
          const start = Math.max(0, index - windowSize)
          const end = Math.min(notes.length, index + lowerTag.length + windowSize)

          contexts.push(notes.slice(start, end).trim())

          index += lowerTag.length
        }

        return contexts
      }
      // --------------------------------------------------------
      // CASE B — Evidence exists → call LLM for interpretation
      // --------------------------------------------------------

      const systemPrompt = `
        You are an analytical practice coach for Indian classical music.

        Your task is to generate ONE goal-specific insight.

        You will receive:

        - ONE practice goal
        - ONLY reflections from sessions explicitly tagged with that goal

        You must:

        - Analyze only these reflections.
        - Do NOT introduce other ragas or techniques.
        - Do NOT infer related repertoire.
        - Use notes only to interpret qualitative signal.

        ----------------------------------------
        TEMPORAL RULES
        ----------------------------------------

        - All reflections belong to a rolling time window.
        - Weight recent reflections more heavily.

        ----------------------------------------
        INSIGHT RULES
        ----------------------------------------

        Determine the direction of signal:

        improvement → confidence_delta = 1  
        mixed/inconsistent → confidence_delta = 0  
        decline → confidence_delta = -1  

        Signals come from qualitative descriptions:
        clarity, comfort, control, struggle, tone, stability, confidence.

        Frequency alone does not determine progress.

        ----------------------------------------
        OUTPUT REQUIREMENTS
        ----------------------------------------

        Return valid JSON only:

        {
          "item": "string",
          "confidence_delta": -1 | 0 | 1,
          "evidence": "string"
        }

        
        The insight must refer ONLY to the provided goal tag.

        FORMAT REQUIREMENT:

        The "item" string MUST begin with:

        <Goal Tag>: <short assessment sentence>

        Examples:
        "Puriya Dhanashri: Stability has improved in recent sessions."
        "Bol Taan: Control appears inconsistent."
        "Marwa: Tone clarity has declined slightly."

        Do not include introductory phrases.
        Do not restate the goal separately.
        Do not include coaching advice.
        Keep the assessment concise and factual
        `

              const userPrompt = `
        GOAL:
        ${goal.type}: ${goal.tag}${goal.intent ? ` (${goal.intent})` : ""}

        REFLECTIONS FROM TAGGED SESSIONS:
       ${reflections
          .flatMap(r =>
            extractGoalContexts(r.notes, goal.tag)
              .map(ctx => `- ${r.date}: ${ctx}`)
          )
          .join("\n")}
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
            name: "goal_insight",
            strict: true,
            schema: {
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
        }
      })

      const content = completion.choices[0].message.content

      if (content) {
        insights.push(JSON.parse(content))
      }
    }

    // ------------------------------------------------------------
    // STEP 5 — Return final structured result
    // ------------------------------------------------------------

    return new Response(
      JSON.stringify({ items: insights }),
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


// ------------------------------------------------------------
// Types
// ------------------------------------------------------------

export type ReflectionRequest = {
  week_start: string
  reflections: Array<{
    date: string
    notes: string
    tags: string[]          // ← REQUIRED now
    metrics: Record<string, number>
  }>
  goals: Array<{
    type: string
    tag: string
    intent?: string
  }>
}

type InsightItem = {
  item: string
  confidence_delta: -1 | 0 | 1
  evidence: string
}