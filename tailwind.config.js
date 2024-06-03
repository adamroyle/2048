module.exports = {
  content: ["./index.html", "./src/**/*.{gleam,mjs}"],
  theme: {
    extend: {
      animation: {
        "pop-in": "pop-in 0.2s ease-in-out forwards .2s",
      },
      keyframes: {
        "pop-in": {
          from: { transform: "scale(0)" },
          to: { transform: "scale(1)" },
        },
      },
    },
  },
  plugins: [],
};
