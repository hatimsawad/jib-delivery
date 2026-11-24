grant execute on function private.admin_mark_courier_cash_handed(uuid) to authenticated;
grant execute on function private.admin_mark_courier_fee_paid(uuid) to authenticated;
grant execute on function private.admin_set_order_delivery_fee(uuid,numeric) to authenticated;
grant execute on function private.courier_complete_delivery(uuid,numeric) to authenticated;
grant execute on function private.courier_confirm_purchase(uuid,numeric) to authenticated;
