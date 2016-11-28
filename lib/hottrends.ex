defmodule HotTrends do
  @doc """
  Parse today's Google HotTrends feed and append ``articleImages`` key to the response.
  """
  require Logger

  @endpoint Application.get_env(:hottrends, :api).endpoint

  def start() do
    @endpoint
    |> HTTPoison.get!
    |> parse_feed
    |> Enum.map(&Task.async(fn ->
        get_source_photo(&1)
      end))
    |> Enum.map(&Task.await/1)
  end

  defp parse_feed(http_response) do
    http_response
      |> Map.get(:body)
      |> Poison.decode!
      |> Map.get("trendsByDateList")
      |> Enum.at(0)
      |> Map.get("trendsList")
  end

  defp get_source_photo(article) do
    image_url = Map.get(article, "imgLinkUrl")

    if image_url do
      image_url
        |> HTTPoison.get!
        |> Map.get(:body)
        |> extract_photo_url
        |> merge_photo_with_article(article)
    else
      article
    end
  end

  defp extract_photo_url(html) do
    html
      |> Floki.find("meta[property=\"og:image\"], meta[itemprop=\"url\"]")
      |> Floki.attribute("content")
  end

  defp merge_photo_with_article(photo, article) do
    Map.put(article, "articleImages", photo)
  end

end
