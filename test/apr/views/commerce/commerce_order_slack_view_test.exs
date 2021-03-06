defmodule Apr.Views.CommerceOrderSlackViewTest do
  use ExUnit.Case, async: true
  alias Apr.Views.CommerceOrderSlackView
  alias Apr.Fixtures
  alias Apr.Subscriptions.Subscription
  import Mox

  @subscription %Subscription{}
  @fraud_theme_subscription %Subscription{theme: "fraud"}

  setup do
    expect(Apr.PaymentsMock, :payment_info, fn _, _ ->
      {:ok, %{charge_data: %{liability_shift: true}, card_country: "XY", zip_check: true, cvc_check: true}}
    end)

    :ok
  end

  test "submitted buy order" do
    event = Fixtures.commerce_order_event()
    slack_view = CommerceOrderSlackView.render(@subscription, event, "order.submitted")
    assert slack_view.text == "🤞 Submitted  :verified: <https://www.artsy.net/artwork/artwork1| >"
    assert slack_view[:unfurl_links] == true
  end

  test "submitted offer order" do
    event = Fixtures.commerce_offer_order()
    slack_view = CommerceOrderSlackView.render(@subscription, event, "order.submitted")
    assert slack_view.text == "🤞 Offer Submitted <https://www.artsy.net/artwork/artwork1| >"
    assert slack_view[:unfurl_links] == true
  end

  test "approved order" do
    event = Fixtures.commerce_order_event("approved")
    slack_view = CommerceOrderSlackView.render(@subscription, event, "order.approved")
    assert slack_view.text == ":yes: Approved <https://www.artsy.net/artwork/artwork1| >"
    assert slack_view[:unfurl_links] == true
  end

  test "refunded order" do
    event = Fixtures.commerce_order_event("refunded")
    slack_view = CommerceOrderSlackView.render(@subscription, event, "order.refunded")
    assert slack_view.text == ":sad-parrot: Refunded <https://www.artsy.net/artwork/artwork1| >"
    assert slack_view[:unfurl_links] == true
  end

  test "fulfilled order" do
    event = Fixtures.commerce_order_event("fulfilled")
    slack_view = CommerceOrderSlackView.render(@subscription, event, "order.fulfilled")

    assert slack_view.text ==
             ":shipitmoveit: Fulfilled <https://www.artsy.net/artwork/artwork1| >"

    assert slack_view[:unfurl_links] == true
  end

  test "pending_approval order" do
    event = Fixtures.commerce_order_event("pending_approval")
    slack_view = CommerceOrderSlackView.render(@subscription, event, "order.pending_approval")

    assert slack_view.text ==
             ":hourglass: Waiting Approval <https://www.artsy.net/artwork/artwork1| >"

    assert slack_view[:unfurl_links] == true
  end

  test "pending_fulfillment order" do
    event = Fixtures.commerce_order_event("pending_fulfillment")
    slack_view = CommerceOrderSlackView.render(@subscription, event, "order.pending_fulfillment")

    assert slack_view.text ==
             ":hourglass: Waiting Shipping <https://www.artsy.net/artwork/artwork1| >"

    assert slack_view[:unfurl_links] == true
  end

  test "returns nil for subscription with fraud theme and events other than submit" do
    event = Fixtures.commerce_order_event("created")
    slack_view = CommerceOrderSlackView.render(@fraud_theme_subscription, event, "order.created")
    assert is_nil(slack_view)
  end

  test "returns nil for subscription with fraud theme and submitted orders below threshold" do
    event = Fixtures.commerce_order_event("submitted", %{"items_total_cents" => 2999_00})

    slack_view = CommerceOrderSlackView.render(@fraud_theme_subscription, event, "order.submitted")
    assert is_nil(slack_view)
  end

  test "returns message for subscription with fraud theme and total cents below threshold" do
    event = Fixtures.commerce_order_event("submitted", %{"items_total_cents" => 3000_00})

    slack_view = CommerceOrderSlackView.render(@fraud_theme_subscription, event, "order.submitted")
    refute is_nil(slack_view.text)
  end
end
