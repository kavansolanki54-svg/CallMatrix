"use client";

import React, { createContext, useContext, useState, useCallback, useEffect } from "react";
import Alert from "@/components/ui/alert/Alert";

interface AlertItem {
  id: string;
  variant: "success" | "error" | "warning" | "info";
  title: string;
  message: string;
}

interface AlertContextType {
  showAlert: (variant: "success" | "error" | "warning" | "info", title: string, message: string) => void;
}

const AlertContext = createContext<AlertContextType | undefined>(undefined);

// A wrapper component to manage individual alert mount, auto-close timers, and exit animations
const ToastWrapper: React.FC<{
  children: React.ReactNode;
  onClose: () => void;
  autoCloseDuration?: number;
}> = ({ children, onClose, autoCloseDuration = 5000 }) => {
  const [isExiting, setIsExiting] = useState(false);

  const triggerClose = useCallback(() => {
    setIsExiting(true);
    // Let the animation finish before removing the element from DOM
    setTimeout(() => {
      onClose();
    }, 280);
  }, [onClose]);

  useEffect(() => {
    const timer = setTimeout(() => {
      triggerClose();
    }, autoCloseDuration);

    return () => clearTimeout(timer);
  }, [autoCloseDuration, triggerClose]);

  return (
    <div
      className={`pointer-events-auto shadow-md rounded-lg overflow-hidden transition-all duration-300 ${
        isExiting ? "animate-alert-slide-out" : "animate-alert-slide-in"
      }`}
    >
      {React.cloneElement(children as React.ReactElement<any>, {
        onClose: triggerClose,
      })}
    </div>
  );
};

export const AlertProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [alerts, setAlerts] = useState<AlertItem[]>([]);

  const showAlert = useCallback(
    (variant: "success" | "error" | "warning" | "info", title: string, message: string) => {
      const id = Math.random().toString(36).substring(2, 9);
      setAlerts((prev) => [...prev, { id, variant, title, message }]);
    },
    []
  );

  const removeAlert = useCallback((id: string) => {
    setAlerts((prev) => prev.filter((a) => a.id !== id));
  }, []);

  return (
    <AlertContext.Provider value={{ showAlert }}>
      {children}
      
      {/* Self-contained CSS injection for fluid animations */}
      <style dangerouslySetInnerHTML={{ __html: `
        @keyframes slideInRight {
          0% {
            transform: translateX(120%) scale(0.9);
            opacity: 0;
          }
          100% {
            transform: translateX(0) scale(1);
            opacity: 1;
          }
        }
        @keyframes slideOutRight {
          0% {
            transform: translateX(0) scale(1);
            opacity: 1;
            max-height: 150px;
            margin-bottom: 12px;
          }
          100% {
            transform: translateX(120%) scale(0.9);
            opacity: 0;
            max-height: 0;
            margin-bottom: 0;
            padding-top: 0;
            padding-bottom: 0;
            border-width: 0;
          }
        }
        .animate-alert-slide-in {
          animation: slideInRight 0.35s cubic-bezier(0.16, 1, 0.3, 1) forwards;
        }
        .animate-alert-slide-out {
          animation: slideOutRight 0.28s cubic-bezier(0.7, 0, 0.84, 0) forwards;
        }
      ` }} />

      {/* Floating Container (z-index 9999 to show above modals) */}
      <div className="fixed top-6 right-6 z-[9999] flex flex-col gap-3 w-full max-w-[90%] sm:max-w-md pointer-events-none">
        {alerts.map((alert) => (
          <ToastWrapper key={alert.id} onClose={() => removeAlert(alert.id)}>
            <Alert
              variant={alert.variant}
              title={alert.title}
              message={alert.message}
            />
          </ToastWrapper>
        ))}
      </div>
    </AlertContext.Provider>
  );
};

export const useAlert = () => {
  const context = useContext(AlertContext);
  if (!context) {
    throw new Error("useAlert must be used within an AlertProvider");
  }
  return context;
};
