defmodule ExByteflow.Retry do
  require Logger

  @spec retry(Req.Response.t()) :: {:delay, integer}
  def retry(%{:status => status} = response) when is_integer(status) and status == 420 do
    {delay, _} =
      Req.Response.get_header(response, "retry-after") |> List.first() |> Integer.parse()

    Logger.debug(
      "Received rate-limit response from Byteflow. Waiting #{delay} seconds before making next request"
    )

    delay_ms = delay * 1000
    {:delay, delay_ms}
  end
end
