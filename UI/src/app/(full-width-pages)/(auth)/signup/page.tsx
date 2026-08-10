import SignUpForm from "@/components/auth/SignUpForm";
import { Metadata } from "next";

export const metadata: Metadata = {
  title: "Sign Up | Callalyze Workspace",
  description: "Create a new Callalyze Enterprise Workspace account.",
};

export default function SignUp() {
  return <SignUpForm />;
}
