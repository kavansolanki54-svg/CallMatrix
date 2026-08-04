import SignInForm from "@/components/auth/SignInForm";
import { Metadata } from "next";

export const metadata: Metadata = {
  title: "Sign In | CallMatrix Workspace",
  description: "Sign in to access your CallMatrix Enterprise Workspace.",
};

export default function SignIn() {
  return <SignInForm />;
}
