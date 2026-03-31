const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { senderName, senderEmail, message } = await req.json();

    if (!message) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    if (!resendApiKey) {
      return new Response(JSON.stringify({ error: "RESEND_API_KEY not set" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const fromAddress = Deno.env.get("RESEND_FROM_EMAIL") ?? "Pekárna <onboarding@resend.dev>";

    const emailHtml = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #4a2c0a;">Nová zpráva od zaměstnance</h2>
        <p><strong>Od:</strong> ${senderName ?? "Neznámý"} (${senderEmail ?? "—"})</p>
        <hr style="border: 1px solid #eee; margin: 16px 0;" />
        <p style="white-space: pre-wrap;">${message}</p>
        <hr style="border: 1px solid #eee; margin: 24px 0;" />
        <p style="color: #888; font-size: 12px;">Tato zpráva byla odeslána z aplikace Bánovská pekárna.</p>
      </div>
    `;

    const resendRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: fromAddress,
        to: ["info@banovpekarna.online"],
        subject: `Zpráva od zaměstnance: ${senderName ?? senderEmail ?? "Neznámý"}`,
        html: emailHtml,
      }),
    });

    const data = await resendRes.json();

    return new Response(JSON.stringify(data), {
      status: resendRes.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
