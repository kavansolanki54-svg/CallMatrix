import SignUpForm from "@/components/auth/SignUpForm";
import { Metadata } from "next";

export const metadata: Metadata = {
  title: "Sign Up | CallMatrix Workspace",
  description: "Create a new CallMatrix Enterprise Workspace account.",
};

export default function SignUp() {
  return <SignUpForm />;
}
