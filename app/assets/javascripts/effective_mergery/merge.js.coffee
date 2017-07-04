loadAttributes = (event) ->
  $obj = $(event.currentTarget)

  id = parseInt($obj.val())
  type = $obj.closest('form').find("input[name='effective_merge[type]']").val()

  selector = if ($obj.attr('name') == 'effective_merge[source_id]') then '.source' else '.target'
  content = $obj.closest('form').find(selector).first()

  url = "/admin/merge/attributes?id=#{id}&type=#{type}"

  if id != undefined && id != NaN && id > 0 && type.length > 0
    content.load(url, (response, status, xhr) =>
      content.html('<p>This item is unavailable (ajax error)</p>') if status == 'error'
    )
  else
    content.html('')

$(document).on 'change', "select[name='effective_merge[source_id]']", (event) -> loadAttributes(event)
$(document).on 'change', "select[name='effective_merge[target_id]']", (event) -> loadAttributes(event)
