defmodule ExtractionPointWeb.WebLinkController do
  use ExtractionPointWeb, :controller

  alias ExtractionPoint.Exporter

  action_fallback ExtractionPointWeb.FallbackController

  NimbleCSV.define(CSVParser, separator: "\t")

  @bom :unicode.encoding_to_bom({:utf16, :little})

  def index(%Plug.Conn{request_path: "/web-links.csv"} = conn, _params) do
    conn =
      conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", ~s[inline; filename=web-links.csv"])
      |> send_chunked(:ok)

    Exporter.list_type(:web_link, fn columns, stream ->
      conn |> chunk(@bom)

      headers = [columns]
        |> CSVParser.dump_to_iodata()
        |> :unicode.characters_to_binary(:utf8, {:utf16, :little})

      conn |> chunk(headers)

      for result <- stream do
        csv_rows = result.rows
          |> CSVParser.dump_to_iodata()
          |> :unicode.characters_to_binary(:utf8, {:utf16, :little})

        conn |> chunk(csv_rows)
      end
    end)

    conn
  end

  def index(conn, _params) do
    {columns, web_links} = Exporter.list_type(:web_link)

    render(conn, :index, columns: columns, web_links: web_links)
  end

  def show(conn, %{"id" => id}) do
    {columns, web_link} = Exporter.get_type(:web_link, id)

    render(conn, :show, columns: columns, web_link: web_link)
  end
end
