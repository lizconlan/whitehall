class GovUkDeliveryNotificationJob < Struct.new(:id)

  def perform
    Whitehall.govuk_delivery_client.notify(edition.govuk_delivery_tags, edition.title, email_body)
  rescue GdsApi::HTTPErrorResponse => exception
    # we handle 400 responses because that is what the API returns if there are no subscribers
    raise unless exception.code == 400
  end

  def edition
    @edition ||= Edition.find(id)
  end

  def edition_url
    edition.document_url(edition, host: Whitehall.public_host)
  end

  def email_body
%Q(<div class="rss_item" style="margin-bottom: 2em;">
  <div class="rss_title" style="font-weight: bold; font-size: 120%; margin: 0 0 0.3em; padding: 0;">
    <a href="#{edition_url}">#{escape(edition.title)}</a>
  </div>
  <div class="rss_pub_date" style="font-size: 90%; margin: 0 0 0.3em; padding: 0; color: #666666; font-style: italic;">#{edition.public_timestamp}</div>
  <br />
  <div class="rss_description" style="margin: 0 0 0.3em; padding: 0;">#{escape(edition.summary)}</div>
</div>)
  end

  private

  def escape(string)
    ERB::Util.html_escape(string)
  end
end
