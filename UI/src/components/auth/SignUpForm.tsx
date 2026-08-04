"use client";
import Checkbox from "@/components/form/input/Checkbox";
import Input from "@/components/form/input/InputField";
import Label from "@/components/form/Label";
import { ChevronLeftIcon, EyeCloseIcon, EyeIcon } from "@/icons";
import { authService } from "@/lib/services";
import Link from "next/link";
import { useRouter } from "next/navigation";
import React, { useState } from "react";

export default function SignUpForm() {
  const router = useRouter();
  const [showPassword, setShowPassword] = useState(false);
  const [isChecked, setIsChecked] = useState(false);
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isChecked) {
      setError("Please agree to the Terms and Conditions to proceed.");
      return;
    }

    setLoading(true);
    setError("");

    try {
      const fullName = `${firstName} ${lastName}`.trim() || email.split('@')[0];
      const signupResponse = await authService.signUp({
        fullName,
        companyName: fullName + " Enterprise",
        email,
        password,
      });

      if (signupResponse.success) {
        // Redirect to sign in page so the user can enter their credentials
        router.push("/signin");
      } else {
        setError(signupResponse.message || "Failed to create account");
      }
    } catch (err: any) {
      console.error("SignUp failed", err);
      setError(err.response?.data?.message || "Failed to connect to CallMatrix Web API");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col flex-1 lg:w-1/2 w-full justify-center p-6 md:p-12 relative overflow-hidden bg-gray-50/50 dark:bg-gray-900/30">
      {/* Premium ambient glow blobs */}
      <div className="absolute top-1/4 left-1/4 w-80 h-80 bg-brand-500/10 dark:bg-brand-500/15 rounded-full blur-[100px] -z-10 animate-pulse"></div>
      <div className="absolute bottom-1/4 right-1/4 w-80 h-80 bg-indigo-500/10 dark:bg-indigo-500/15 rounded-full blur-[100px] -z-10 animate-pulse"></div>

      <div className="w-full max-w-md mx-auto mb-6">
        <Link
          href="/signin"
          className="inline-flex items-center text-sm font-semibold text-gray-500 transition-colors hover:text-brand-500 dark:text-gray-400 dark:hover:text-brand-400 gap-1.5"
        >
          <ChevronLeftIcon className="w-4 h-4" />
          Back to sign in
        </Link>
      </div>

      <div className="flex flex-col justify-center w-full max-w-md mx-auto bg-white/80 dark:bg-gray-900/80 backdrop-blur-xl border border-gray-100 dark:border-gray-800 p-8 rounded-2xl shadow-[0_20px_50px_rgba(0,0,0,0.08)] dark:shadow-[0_20px_50px_rgba(0,0,0,0.25)] relative transition-all duration-300 hover:shadow-[0_30px_60px_rgba(70,95,255,0.08)] dark:hover:shadow-[0_30px_60px_rgba(70,95,255,0.15)]">
        <div>
          <div className="mb-6">
            <h1 className="text-2xl font-extrabold text-gray-900 dark:text-white mb-2 tracking-tight">
              Create an account
            </h1>
            <p className="text-sm text-gray-500 dark:text-gray-400 font-medium">
              Start monitoring your calling agents today
            </p>
          </div>

          {error && (
            <div className="mb-5 p-4 rounded-xl bg-red-50/80 dark:bg-red-950/20 border border-red-200/50 dark:border-red-800/40 text-red-600 dark:text-red-400 text-sm font-semibold flex items-center gap-2 animate-shake">
              <span className="w-1.5 h-1.5 rounded-full bg-red-500"></span>
              {error}
            </div>
          )}

          <div>
            <form onSubmit={handleSubmit}>
              <div className="space-y-4">
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  {/* First Name */}
                  <div className="sm:col-span-1">
                    <Label className="text-gray-700 dark:text-gray-300 font-medium mb-1 block">
                      First Name<span className="text-error-500">*</span>
                    </Label>
                    <input
                      type="text"
                      id="fname"
                      name="fname"
                      placeholder="First name"
                      value={firstName}
                      onChange={(e) => setFirstName(e.target.value)}
                      required
                      className="w-full px-4 py-2.5 rounded-xl border border-gray-200 dark:border-gray-800 bg-white/50 dark:bg-gray-900/50 text-gray-900 dark:text-white focus:ring-2 focus:ring-brand-500/30 focus:border-brand-500 focus:outline-none transition-all duration-200 text-sm"
                    />
                  </div>
                  {/* Last Name */}
                  <div className="sm:col-span-1">
                    <Label className="text-gray-700 dark:text-gray-300 font-medium mb-1 block">
                      Last Name<span className="text-error-500">*</span>
                    </Label>
                    <input
                      type="text"
                      id="lname"
                      name="lname"
                      placeholder="Last name"
                      value={lastName}
                      onChange={(e) => setLastName(e.target.value)}
                      required
                      className="w-full px-4 py-2.5 rounded-xl border border-gray-200 dark:border-gray-800 bg-white/50 dark:bg-gray-900/50 text-gray-900 dark:text-white focus:ring-2 focus:ring-brand-500/30 focus:border-brand-500 focus:outline-none transition-all duration-200 text-sm"
                    />
                  </div>
                </div>
                {/* Email */}
                <div>
                  <Label className="text-gray-700 dark:text-gray-300 font-medium mb-1 block">
                    Email<span className="text-error-500">*</span>
                  </Label>
                  <input
                    type="email"
                    id="email"
                    name="email"
                    placeholder="name@company.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    className="w-full px-4 py-2.5 rounded-xl border border-gray-200 dark:border-gray-800 bg-white/50 dark:bg-gray-900/50 text-gray-900 dark:text-white focus:ring-2 focus:ring-brand-500/30 focus:border-brand-500 focus:outline-none transition-all duration-200 text-sm"
                  />
                </div>
                {/* Password */}
                <div>
                  <Label className="text-gray-700 dark:text-gray-300 font-medium mb-1 block">
                    Password<span className="text-error-500">*</span>
                  </Label>
                  <div className="relative">
                    <input
                      placeholder="Choose secure password"
                      type={showPassword ? "text" : "password"}
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      required
                      className="w-full px-4 py-2.5 rounded-xl border border-gray-200 dark:border-gray-800 bg-white/50 dark:bg-gray-900/50 text-gray-900 dark:text-white focus:ring-2 focus:ring-brand-500/30 focus:border-brand-500 focus:outline-none transition-all duration-200 text-sm"
                    />
                    <span
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute z-30 -translate-y-1/2 cursor-pointer right-4 top-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition-colors"
                    >
                      {showPassword ? (
                        <EyeIcon className="w-5 h-5" />
                      ) : (
                        <EyeCloseIcon className="w-5 h-5" />
                      )}
                    </span>
                  </div>
                </div>
                {/* Checkbox */}
                <div className="flex items-start gap-3 pt-1">
                  <Checkbox
                    className="w-5 h-5 mt-0.5"
                    checked={isChecked}
                    onChange={setIsChecked}
                  />
                  <p className="inline-block font-normal text-xs text-gray-500 dark:text-gray-400 leading-tight">
                    By creating an account, you agree to our{" "}
                    <span className="text-gray-700 dark:text-white/90 font-semibold cursor-pointer hover:underline">
                      Terms
                    </span>{" "}
                    and{" "}
                    <span className="text-gray-700 dark:text-white font-semibold cursor-pointer hover:underline">
                      Privacy Policy
                    </span>.
                  </p>
                </div>
                {/* Button */}
                <div className="pt-2">
                  <button 
                    type="submit"
                    disabled={loading}
                    className="flex items-center justify-center w-full py-3 text-sm font-semibold text-white bg-gradient-to-r from-brand-600 to-indigo-600 hover:from-brand-500 hover:to-indigo-500 rounded-xl shadow-[0_8px_30px_rgb(70,95,255,0.2)] hover:shadow-[0_8px_30px_rgb(70,95,255,0.35)] active:scale-[0.98] transition-all duration-200 disabled:opacity-50"
                  >
                    {loading ? "Creating Account..." : "Sign Up"}
                  </button>
                </div>
              </div>
            </form>

            <div className="mt-6 text-center border-t border-gray-100 dark:border-gray-800/80 pt-5">
              <p className="text-sm font-medium text-gray-500 dark:text-gray-400">
                Already have an account?{" "}
                <Link
                  href="/signin"
                  className="text-brand-500 hover:text-brand-600 dark:text-brand-400 font-bold transition-colors"
                >
                  Sign In
                </Link>
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
