defmodule ExByteflow.Api do
  require Logger
  alias ExByteflow.Config
  alias ExByteflow.Retry

  @req Req.new(
         base_url: Config.base_url(),
         headers: %{"api_key" => Config.api_key(), "Retry-Id" => Nanoid.generate()}
       )
       |> Req.Request.append_error_steps(retry: &Retry.retry/1)

  @spec send_message(String.t(), String.t()) :: term()
  def send_message!(destination_number, content) do
    Logger.debug(
      "Sending message with content [#{content}] to phone number #{destination_number}"
    )

    response =
      Req.post!(@req,
        url: "/sendMessage",
        json: %{destination_number: destination_number, message_content: content}
      )

    response.body
  end

  def send_message(destination_number, content) do
    Logger.debug(
      "Sending message with content [#{content}] to phone number #{destination_number}"
    )

    do_request(
      Req.post(@req,
        url: "/sendMessage",
        json: %{destination_number: destination_number, message_content: content}
      )
    )
  end

  @spec send_message(
          String.t(),
          String.t(),
          String.t()
        ) :: term()
  def send_message!(destination_number, content, file_path) do
    attachment_url = upload_attachment(file_path)

    send_message!(destination_number, "#{content}\n#{attachment_url}")
  end

  def send_message(destination_number, content, file_path) do
    attachment_url = upload_attachment(file_path)

    send_message(destination_number, "#{content}\n#{attachment_url}")
  end

  @spec lookup_number(String.t()) :: term()
  def lookup_number!(phone_number) do
    response =
      Req.get!(@req,
        url: "/lookupNumber",
        params: [phone_number: phone_number, advanced_mode: false]
      )

    response.body
  end

  def lookup_number(phone_number) do
    do_request(
      Req.get(@req,
        url: "/lookupNumber",
        params: [phone_number: phone_number, advanced_mode: false]
      )
    )
  end

  @spec lookup_number(String.t(), :advanced_mode) :: term()
  def lookup_number!(phone_number, :advanced_mode) do
    response =
      Req.get!(@req,
        url: "/lookupNumber",
        params: [phone_number: phone_number, advanced_mode: true]
      )

    response.body
  end

  def lookup_number(phone_number, :advanced_mode) do
    do_request(
      Req.get(@req,
        url: "/lookupNumber",
        params: [phone_number: phone_number, advanced_mode: true]
      )
    )
  end

  @spec register_number(String.t()) :: term()
  def register_number!(phone_number) do
    response = Req.post!(@req, url: "/registerNumber", json: %{phone_number: phone_number})

    response.body
  end

  def register_number(phone_number) do
    do_request(Req.post(@req, url: "/registerNumber", json: %{phone_number: phone_number}))
  end

  defp do_request(request) do
    case request do
      {:ok, response} -> {:ok, response.body}
      {:error, exception} -> {:error, exception}
    end
  end

  defp upload_attachment(file_path) do
    Logger.debug("Uploading file at path #{file_path} as an attachment")

    Logger.debug("Retriving presigned URLs from Byteflow for upload")

    presigned_url_resp =
      Req.post!(@req, url: "/uploadMedia", json: %{filename: Path.basename(file_path)})

    upload_url = presigned_url_resp.body["uploadURL"]
    get_url = presigned_url_resp.body["getURL"]

    Logger.debug("Upload URL: #{upload_url}\nGet URL: #{get_url}")

    file_data = File.read!(file_path)
    Req.put!(upload_url, body: file_data)
    Logger.debug("File uploaded successfully")

    get_url
  end
end
