import { redirect } from "next/navigation";
import { createClient } from "../lib/supabase/server";

type AdminProfile = {
  role: string;
  full_name: string | null;
};

export async function requireAdmin() {
  const supabase = await createClient();
  const { data: { user }, error: userError } = await supabase.auth.getUser();

  if (userError || !user) redirect("/login");

  const { data: profileData, error: profileError } = await supabase
    .from("profiles")
    .select("role, full_name")
    .eq("id", user.id)
    .maybeSingle();

  const profile = profileData as unknown as AdminProfile | null;

  if (profileError || profile?.role !== "admin") {
    redirect("/login?denied=1");
  }

  return { supabase, user, profile };
}
