import Config

config :radlab,
  http_endpoint: "http://localhost:3000",
  chunk_size: 20,
  client: Radlab.Firmware.HttpClient,
  upload_file_path: "example.hex"

import_config "#{Mix.env()}.exs"
