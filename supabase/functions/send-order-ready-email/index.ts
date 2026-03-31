const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { userEmail, userName, orderId, orderTotal } = await req.json();

    if (!userEmail || !orderId) {
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

    const emailHtml = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #4a2c0a;">Vaše objednávka je připravena 🎉</h2>
        <p>Dobrý den, <strong>${userName ?? userEmail}</strong>,</p>
        <p>Rádi vám oznamujeme, že vaše objednávka č. <strong>${orderId}</strong> je připravena k vyzvednutí.</p>
        ${orderTotal ? `<p>Celková cena: <strong>${orderTotal} Kč</strong></p>` : ""}
        <p>Těšíme se na vaši návštěvu!</p>
        <hr style="border: 1px solid #eee; margin: 24px 0;" />
        <p style="color: #888; font-size: 12px;">Tato zpráva byla odeslána automaticky, prosíme neodpovídejte na ni.</p>
      </div>
    `;

    const resendRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        // Free version: leave as onboarding@resend.dev (only sends to your own Resend account email)
        // Full version: replace with noreply@yourdomain.com after verifying your domain in Resend
        from: "Pekárna <onboarding@resend.dev>",
        to: [userEmail],
        subject: `Objednávka č. ${orderId} je připravena k vyzvednutí`,
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
