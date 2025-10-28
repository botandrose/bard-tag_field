import resolve from "@rollup/plugin-node-resolve"
import commonjs from '@rollup/plugin-commonjs';

export default [
  {
    input: "./index.js",
    output: [
      {
        file: "../app/assets/javascripts/input-tag.js",
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