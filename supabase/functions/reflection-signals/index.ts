Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const body = await req.json() as ReflectionRequest

    // Minimal validation
    if (!body.week_start || !Array.isArray(body.reflections)) {
      return new Response(
        JSON.stringify({ error: "Invalid payload" }),
        { status: 400 }
      );
    }

    // ---- MOCK LOGIC ----
    // Always return a fake signal for now
    const response = {
      items: [
        {
          item: "bol taan",
          confidence_delta: 1,
          evidence: "felt smoother compared to earlier sessions"
        }
      ]
    };

    return new Response(
      JSON.stringify(response),
      {
        headers: { "Content-Type": "application/json" },
        status: 200
      }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Malformed JSON" }),
      { status: 400 }
    );
  }
});


export type ReflectionRequest= {
  week_start: string;
  reflections: Array<{
    date: string;
    notes: string;
    metrics: Record<string, number>;
  }>;
};
