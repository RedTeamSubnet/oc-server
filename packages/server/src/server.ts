import { webHandler } from "./routes"

const port = parseInt(process.env.PORT || "3000")
const host = process.env.HOST || "0.0.0.0"

const { handler } = webHandler()

Bun.serve({
  port,
  hostname: host,
  fetch: handler,
})
