defmodule ExByteflow.Api do
  alias ExByteflow.Config

  @req Req.new(base_url: Config.base_url(), headers: %{"api_key" => Config.api_key()})

  @spec send_message(String.t(), String.t()) :: any
  def send_message(destination_number, content) do
    response =
      Req.post!(@req,
        url: "/sendMessage",
        json: %{destination_number: destination_number, message_content: content}
      )

    response.body
  end

  def send_message(destination_number, content, file_path) do
    attachment_url = upload_attachment(file_path)

    send_message(destination_number, "#{content}\n#{attachment_url}")
  end

  defp upload_attachment(file_path) do
    presigned_url_resp =
      Req.post!(@req, url: "/uploadMedia", json: %{filename: Path.basename(file_path)})

    upload_url = presigned_url_resp.body["uploadURL"]
    get_url = presigned_url_resp.body["getURL"]

    file_data = File.read!(file_path)
    Req.put!(upload_url, body: file_data)

    get_url
  end

  def lookup_number(phone_number) do
    response =
      Req.get!(@req,
        url: "/lookupNumber",
        params: [phone_number: phone_number, advanced_mode: false]
      )

    response.body
  end

  def lookup_number(phone_number, :advanced_mode) do
    response =
      Req.get!(@req,
        url: "/lookupNumber",
        params: [phone_number: phone_number, advanced_mode: true]
      )

    response.body
  end

  def register_number(phone_number) do
    response = Req.post!(@req, url: "/registerNumber", json: %{phone_number: phone_number})

    response.body
  end
end
