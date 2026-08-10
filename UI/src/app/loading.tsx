import React from "react";
import Loader from "@/components/ui/loader/Loader";

export default function GlobalLoading() {
  return (
    <div className="flex h-screen w-screen items-center justify-center bg-gray-50 dark:bg-gray-950">
      <Loader size="lg" text="Loading Callalyze..." />
    </div>
  );
}
