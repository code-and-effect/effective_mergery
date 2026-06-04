(function() {
  function loadAttributes(event) {
    var $select = $(event.currentTarget);
    var $form = $select.closest('form');

    var id = parseInt($select.val(), 10);
    var type = $form.find("input[name='effective_merge[type]']").val();

    var selector = ($select.attr('name') === 'effective_merge[source_id]') ? '.source' : '.target';
    var $content = $form.find(selector).first();

    if (id > 0 && type && type.length > 0) {
      var url = '/admin/merge/attributes?id=' + id + '&type=' + encodeURIComponent(type);

      $content.load(url, function(response, status) {
        if (status === 'error') {
          $content.html('<p>This item is unavailable (ajax error)</p>');
        }
      });
    } else {
      $content.html('');
    }
  }

  $(document).on('change', "select[name='effective_merge[source_id]']", loadAttributes);
  $(document).on('change', "select[name='effective_merge[target_id]']", loadAttributes);
})();
