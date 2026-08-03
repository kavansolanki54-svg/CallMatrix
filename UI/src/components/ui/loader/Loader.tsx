import React from "react";

interface LoaderProps {
  size?: "sm" | "md" | "lg";
  color?: string;
  fullPage?: boolean;
  text?: string;
}

export default function Loader({
  size = "md",
  color = "text-brand-500",
  fullPage = false,
  text,
}: LoaderProps) {
  const sizeClasses = {
    sm: "h-5 w-5 border-2",
    md: "h-8 w-8 border-3",
    lg: "h-12 w-12 border-4",
  };

  const spinner = (
    <div className="flex flex-col items-center justify-center space-y-3">
      <div
        className={`animate-spin rounded-full border-solid border-gray-200 dark:border-gray-800 ${color} ${sizeClasses[size]}`}
        style={{ borderTopColor: "currentColor" }}
      />
      {text && (
        <p className="text-sm font-medium text-gray-500 dark:text-gray-400">
          {text}
        </p>
      )}
    </div>
  );

  if (fullPage) {
    return (
      <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-white/70 dark:bg-gray-950/70 backdrop-blur-xs">
        {spinner}
      </div>
    );
  }

  return spinner;
}
