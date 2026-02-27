import type { Metadata } from "next";
import "./globals.css";
import ChatBot from "./components/ChatBot";

export const metadata: Metadata = {
  title: "Amazon Clone | Premium Shopping",
  description: "A DevOps Reference Architecture",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>
        {children}
        <ChatBot />
      </body>
    </html>
  );
}
