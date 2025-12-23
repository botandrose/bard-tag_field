import resolve from "@rollup/plugin-node-resolve"
import commonjs from "@rollup/plugin-commonjs"

export default [
  {
    input: "./src/input-tag.js",
    output: [
      {
        file: "dist/input-tag.js",
        format: "es",
      },
    ],
    context: "window",
    plugins: [
      resolve(),
      commonjs(),
    ]
  },
]
