"use client";

import Link from "next/link";
import React, { useState } from "react";

interface AlertProps {
  variant: "success" | "error" | "warning" | "info"; // Alert type
  title: string; // Title of the alert
  message: string; // Message of the alert
  showLink?: boolean; // Whether to show the "Learn More" link
  linkHref?: string; // Link URL
  linkText?: string; // Link text
  onClose?: () => void; // Optional close callback
}

const Alert: React.FC<AlertProps> = ({
  variant,
  title,
  message,
  showLink = false,
  linkHref = "#",
  linkText = "Learn more",
  onClose,
}) => {
  const [isVisible, setIsVisible] = useState(true);

  if (!isVisible) return null;

  const handleClose = () => {
    setIsVisible(false);
    if (onClose) {
      onClose();
    }
  };

  // Styles for each alert variant (matching the reference design)
  const variantStyles = {
    success: {
      container: "border-l-[#0F924A] dark:border-l-[#10B981]",
      iconBorder: "border-[#0F924A] text-[#0F924A] dark:border-[#10B981] dark:text-[#10B981]",
      icon: (
        <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
          <polyline points="20 6 9 17 4 12" />
        </svg>
      ),
    },
    error: {
      container: "border-l-[#D92D20] dark:border-l-[#F04438]",
      iconBorder: "border-[#D92D20] text-[#D92D20] dark:border-[#F04438] dark:text-[#F04438]",
      icon: (
        <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
          <line x1="18" y1="6" x2="6" y2="18" />
          <line x1="6" y1="6" x2="18" y2="18" />
        </svg>
      ),
    },
    warning: {
      container: "border-l-[#DC6803] dark:border-l-[#F79009]",
      iconBorder: "border-[#DC6803] text-[#DC6803] dark:border-[#F79009] dark:text-[#F79009]",
      icon: (
        <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
          <line x1="12" y1="9" x2="12" y2="13" />
          <circle cx="12" cy="17" r="1" fill="currentColor" stroke="none" />
        </svg>
      ),
    },
    info: {
      container: "border-l-[#1570EF] dark:border-l-[#2E90FA]",
      iconBorder: "border-[#1570EF] text-[#1570EF] dark:border-[#2E90FA] dark:text-[#2E90FA]",
      icon: (
        <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
          <line x1="12" y1="16" x2="12" y2="12" />
          <circle cx="12" cy="8" r="1" fill="currentColor" stroke="none" />
        </svg>
      ),
    },
  };

  return (
    <div
      className={`relative w-full rounded-lg border border-gray-100 dark:border-gray-800 bg-white dark:bg-gray-900 shadow-sm p-4 sm:p-5 border-l-[5px] transition-all duration-300 ${variantStyles[variant].container}`}
    >
      <div className="flex items-start justify-between gap-4">
        <div className="flex items-start gap-3.5">
          {/* Circle Icon Container */}
          <div
            className={`flex items-center justify-center w-7 h-7 sm:w-8 sm:h-8 rounded-full border-2 flex-shrink-0 ${variantStyles[variant].iconBorder}`}
          >
            {variantStyles[variant].icon}
          </div>

          {/* Title and Message */}
          <div className="flex-1">
            <h4 className="text-sm sm:text-base font-semibold text-gray-900 dark:text-white leading-snug mb-1">
              {title}
            </h4>
            <p className="text-xs sm:text-sm text-gray-500 dark:text-gray-400 leading-relaxed">
              {message}
            </p>

            {showLink && (
              <Link
                href={linkHref}
                className="inline-block mt-3 text-xs sm:text-sm font-medium text-gray-500 underline dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 transition-colors"
              >
                {linkText}
              </Link>
            )}
          </div>
        </div>

        {/* Close Button */}
        <button
          onClick={handleClose}
          className="text-gray-400 hover:text-gray-600 dark:text-gray-500 dark:hover:text-gray-300 transition-colors p-1 flex-shrink-0 -mt-1 -mr-1"
          aria-label="Close alert"
        >
          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <line x1="18" y1="6" x2="6" y2="18" />
            <line x1="6" y1="6" x2="18" y2="18" />
          </svg>
        </button>
      </div>
    </div>
  );
};

export default Alert;
