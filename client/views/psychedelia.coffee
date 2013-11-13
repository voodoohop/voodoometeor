
#@f = ->
#  filters = ["invert","hue-rotate","contrast","blur","saturate"]
#  filter = _.sample(filters)
#  d3.select(_.sample(d3.selectAll(".mediathumb img")[0])).transition().call(vendor_style("filter", filter+"(1)")).transition().delay(_.random(500,10000)).call(vendor_style("filter", "invert(0)"))
#  setTimeout(f,_.random(1000,20000))
#f()
#console.log("psychedelia")
