import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { importPKCS8, SignJWT } from "npm:jose@5.9.6";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type CallNotification = {
  receiverId: string;
  callId: string;
  callerId: string;
  callerName: string;
  callerAvatar?: string | null;
  callType: "audio" | "video";
};

async function getFirebaseAccessToken(serviceAccount: Record<string, string>) {
  const now = Math.floor(Date.now() / 1000);
  const privateKey = await importPKCS8(
    serviceAccount.private_key.replace(/\\n/g, "\n"),
    "RS256",
  );
  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(serviceAccount.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey);

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!response.ok) {
    throw new Error(`Google OAuth failed: ${await response.text()}`);
  }
  const token = await response.json();
  return token.access_token as string;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = (await request.json()) as CallNotification;
    if (!payload.receiverId || !payload.callId || !payload.callerId) {
      return new Response(JSON.stringify({ error: "Invalid call payload" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { data: receiver, error } = await supabase
      .from("users")
      .select("fcm_token")
      .eq("id", payload.receiverId)
      .maybeSingle();

    if (error) throw error;
    if (!receiver?.fcm_token) {
      return new Response(JSON.stringify({ delivered: false, reason: "no_fcm_token" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const serviceAccount = JSON.parse(
      Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON")!,
    ) as Record<string, string>;
    const accessToken = await getFirebaseAccessToken(serviceAccount);
    const projectId = Deno.env.get("FIREBASE_PROJECT_ID") ?? serviceAccount.project_id;
    const fcmResponse = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token: receiver.fcm_token,
            data: {
              callId: payload.callId,
              callerId: payload.callerId,
              callerName: payload.callerName,
              callerAvatar: payload.callerAvatar ?? "",
              callType: payload.callType,
            },
            android: {
              priority: "HIGH",
              ttl: "45s",
            },
          },
        }),
      },
    );

    if (!fcmResponse.ok) {
      throw new Error(`FCM delivery failed: ${await fcmResponse.text()}`);
    }

    return new Response(JSON.stringify({ delivered: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
