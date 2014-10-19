OB.OBPOSPointOfSale.UI.ToolbarScan.buttons.push
  command: 'cancel'
  i18nLabel: 'TSRR_BtnCancelLineLabel'
  stateless: true
  definition:
    stateless: true
    kbd: null
    cancelModel: null
    printCode: null
    printerProperty: null
    product: null
    stateless: true
    action: (keyboard, txt) ->
      me = @
      kbd = undefined
      cancelModel = undefined
      templatereceipt = undefined
      cancelModel = undefined
      templatereceipt = undefined
      kbd = keyboard

      if keyboard.receipt.attributes.numberOfGuests is undefined
        keyboard.receipt.attributes.numberOfGuests = "Unspecified"
      gpi = keyboard.line.attributes.product.attributes.generic_product_id

      if gpi isnt null
        me = @
        allLines = null
        allLines = keyboard.receipt.get('lines')
        newArray = jQuery.extend(true, {}, keyboard.receipt.get('lines'));
        for line in allLines.models
          if line.get('product').get('generic_product_id') is gpi
            console.error 'present'
          else
            newArray.models.splice(newArray.models.indexOf(line), 1);
        debugger
        window.productsAndPrinters = []
        sendToPrinter = uniquePrinterAndProductGenerator(productInfoGetter, newArray)
        templatereceipt = new OB.DS.HWResource(OB.OBPOSPointOfSale.Print.CancelLinesTemplate)
        if keyboard.receipt.attributes.restaurantTable is undefined
          keyboard.receipt.attributes.restaurantTable.name = "Unspecified"
        if keyboard.receipt.attributes.numberOfGuests is undefined
          keyboard.receipt.attributes.numberOfGuests = "Unspecified"
        OB.POS.hwserver.print templatereceipt,
          order: sendToPrinter
          receiptNo: keyboard.receipt.attributes.documentNo
          tableNo: keyboard.receipt.attributes.restaurantTable.name
          guestNo: keyboard.receipt.attributes.numberOfGuests
          user: keyboard.receipt.attributes.salesRepresentative$_identifier
        _.each newArray.models, (model)->
          enyo.Signals.send "onTransmission", {message: 'cancelled', cid: model.cid}

        OB.UTIL.showSuccess "Orders sent to printers successfully"
        newArray = null
        keyboard.receipt.trigger('scan')
        return
      else
        new OB.DS.Request("com.tasawr.retail.restaurant.data.OrderLineService").exec
          product: keyboard.line.attributes.product.id
        , (data) ->
          if data[0]
            window.asdf = keyboard
            cancelModel = new TSRR.Model.CancelModel(
              order: keyboard.receipt
              message: "Cancel this item"
              printCode: data[0].printCode
              printerProperty: data[0].printerProperty
              productQty: String(kbd.line.attributes.qty)
              description: keyboard.line.attributes.description
            )
            templatereceipt = new OB.DS.HWResource(OB.OBPOSPointOfSale.Print.CancelTemplate)
            OB.POS.hwserver.print templatereceipt,
              order: cancelModel
              receiptNo: keyboard.receipt.attributes.documentNo
              tableNo: keyboard.receipt.attributes.restaurantTable.name
              guestNo: keyboard.receipt.attributes.numberOfGuests
              user: keyboard.receipt.attributes.salesRepresentative$_identifier
            OB.UTIL.showSuccess "Line Cancelled"
            enyo.Signals.send "onTransmission", { message: 'Cancelled', cid: keyboard.line.cid }

          else
            OB.UTIL.showError "No printer is assigned to this product"
            console.log "no data found"
      keyboard.receipt.trigger('scan')
      return





enyo.kind
  name: "TSRR.Model.CancelModel"
  order: null
  message: null
  printCode: null
  printerProperty: null
  productQty: null
  description: null






uniquePrinterAndProductGenerator = (callback, lines) ->
  callback lines

  qty = undefined
  description = undefined
  uniquePrinters = allPrinters.filter((elem, pos) ->
    allPrinters.indexOf(elem) is pos
  )
  j = 0

  while j < uniquePrinters.length
    prodQtyDesc = new Array()
    tempProducts = new Array()
    i = 0

    while i < productsAndPrinters.length
      if ($.inArray(uniquePrinters[j], productsAndPrinters[i][1][0])) >= 0
        prodQtyDesc.push productsAndPrinters[i]

      i++
    printersAndProducts[j] = []
    printersAndProducts[j][0] = uniquePrinters[j]
    printersAndProducts[j][1] = prodQtyDesc
    j++

  printersAndProducts

assignVar = (requests, lines) ->
  tempPrinters = []
  i = 0

  while i < requests.length
    result = JSON.parse(requests[i].xhr.responseText)
    data = result.response.data[0]
    if data
      tempPrinters = data.printerProperty.split(" ")
      j = 0

      while j < tempPrinters.length
        allPrinters.push tempPrinters[j]
        j++
      productsAndPrinters[i] = []
      productsAndPrinters[i][0] = data.printCode
      productsAndPrinters[i][1] = [tempPrinters]
      productsAndPrinters[i][2] = lines.models[i].attributes.qty
      productsAndPrinters[i][3] = lines.models[i].attributes.description

    i++

productInfoGetter = (lines) ->
  i = 0


  while i < lines.length
    if i >= lines.models.length
      break
    else
      ajaxRequest = new enyo.Ajax(
        url: "../../org.openbravo.mobile.core.service.jsonrest/" + "com.tasawr.retail.restaurant.data.OrderLineService" + "/" + encodeURI(JSON.stringify(product: lines.models[i].attributes.product.id))
        cacheBust: false
        sync: true
        method: "GET"
        handleAs: "json"
        contentType: "application/json;charset=utf-8"
        success: (inSender, inResponse) ->
          fail: (inSender, inResponse) ->
            console.log "failed"
      )
      ajaxRequest.go().response("success").error "fail"
      requests.push ajaxRequest
    i++
  $.when.apply(`undefined`, requests).then assignVar(requests, lines)
  requests.length = 0




printersAndProducts = []
allPrinters = []
allProducts = []
window.productsAndPrinters = []
requests = []
