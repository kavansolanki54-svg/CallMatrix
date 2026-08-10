import SignInForm from "@/components/auth/SignInForm";
import { Metadata } from "next";

export const metadata: Metadata = {
  title: "Sign In | Callalyze Workspace",
  description: "Sign in to access your Callalyze Enterprise Workspace.",
};

export default function SignIn() {
  return <SignInForm />;
}
