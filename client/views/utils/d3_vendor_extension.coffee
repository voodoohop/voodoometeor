@obj_vendorize = (base) ->
  d3.entries(base).reduce ((result, attr) ->
    vendors.reduce ((memo, vendor) ->
      memo["-" + vendor + "-" + attr.key] = attr.value
      memo
    ), result
  ), base

vendors = vendors or "moz ms o webkit".split(" ")


@call_vendorize = (base) ->
  styleObj = undefined
  val = undefined
  (selection) ->
    selection.each (datum, idx) ->
      styleObj = {}
      d3.entries(base).map (entry) ->
        val = d3.functor(entry.value).call(this, datum, idx)
        styleObj[entry.key] = val
        vendors.map (vendor) ->
          styleObj["-" + vendor + "-" + entry.key] = val


      d3.select(this).style styleObj


@vendor_style = (property,style) ->
  (selection) ->
    _.each(vendors, (v) ->
      selection.style("-"+v+"-"+property, style);
    )
    selection.style(property, style);
