package org.eclpise.xtend.gwt.stockwatcher.client

import com.google.gwt.core.client.EntryPoint
import com.google.gwt.event.dom.client.KeyCodes
import com.google.gwt.i18n.client.DateTimeFormat
import com.google.gwt.i18n.client.NumberFormat
import com.google.gwt.user.client.Random
import com.google.gwt.user.client.Timer
import com.google.gwt.user.client.Window
import com.google.gwt.user.client.ui.Button
import com.google.gwt.user.client.ui.FlexTable
import com.google.gwt.user.client.ui.HorizontalPanel
import com.google.gwt.user.client.ui.Image
import com.google.gwt.user.client.ui.Label
import com.google.gwt.user.client.ui.Panel
import com.google.gwt.user.client.ui.RootPanel
import com.google.gwt.user.client.ui.TextBox
import com.google.gwt.user.client.ui.VerticalPanel
import com.google.gwt.user.client.ui.Widget
import java.util.Date
import java.util.List

class StockWatcher implements EntryPoint {

	private static final StockResources STOCK_RESOURCES = StockResources.Util.get()

	private static final int REFRESH_INTERVAL = 5000;

	private static final double MAX_PRICE = 100.0;

	private static final double MAX_PRICE_CHANGE = 0.02;

	private Label lastUpdatedLabel

	private TextBox newSymbolTextBox

	private FlexTable stocksFlexTable

	private final List<String> stocks = newArrayList()

	override onModuleLoad() {
		RootPanel.get().add(
			new VerticalPanel => [
				setSize("440px", "290px")
				children = new Image(STOCK_RESOURCES.googlecodePng)
				children = new Label("Stock Watcher") => [
					styleName = STOCK_RESOURCES.stock.gwtLabelStockWatcher
				]
				stocksFlexTable = children = new FlexTable => [
					setText(0, 0, "Symbol")
					setText(0, 1, "Price")
					setText(0, 2, "Change")
					setText(0, 3, "Remove")
					cellPadding = 6
					rowFormatter.addStyleName(0, STOCK_RESOURCES.stock.watchListHeader)
					styleName = STOCK_RESOURCES.stock.watchList
					cellFormatter.addStyleName(0, 1, STOCK_RESOURCES.stock.watchListNumericColumn)
					cellFormatter.addStyleName(0, 2, STOCK_RESOURCES.stock.watchListNumericColumn)
					cellFormatter.addStyleName(0, 3, STOCK_RESOURCES.stock.watchListRemoveColumn)
				]
				children = new HorizontalPanel => [
					styleName = STOCK_RESOURCES.stock.addPanel
					newSymbolTextBox = children = new TextBox => [
						addKeyPressHandler [
							if (charCode == KeyCodes.KEY_ENTER) {
								addStock
							}
						]
						focus = true
					]
					children = new Button("New Button") => [
						styleName = STOCK_RESOURCES.stock.gwtButtonAdd
						addClickHandler [
							addStock
						]
						text = "Add"
					]
					lastUpdatedLabel = children = new Label("New Label")
				]
			], 5, 5)

		val Timer timer = [ |
			refreshWatchList
		]
		timer.scheduleRepeating(REFRESH_INTERVAL)
	}

	def <T extends Widget> setChildren(Panel it, T widget) {
		add(widget)
		widget
	}

	def refreshWatchList() {
		stocks.map [
			val price = Random.nextDouble() * MAX_PRICE;
			val change = price * MAX_PRICE_CHANGE * (Random.nextDouble() * 2.0 - 1.0);
			new StockPrice(it, price, change);
		].forEach[updateTable]
		lastUpdatedLabel.text = "Last update: " +
			DateTimeFormat.getFormat(DateTimeFormat.PredefinedFormat.DATE_TIME_MEDIUM).format(new Date)
	}

	def updateTable(StockPrice stockPrice) {
		if (!stocks.contains(stockPrice.symbol)) {
			return
		}
		val row = stocks.indexOf(stockPrice.symbol) + 1
		val priceText = NumberFormat.getFormat("#,##0.00").format(stockPrice.price)
		val changeFormat = NumberFormat.getFormat("+#,##0.00;-#,##0.00")
		val changeText = changeFormat.format(stockPrice.change)
		val changePercentText = changeFormat.format(stockPrice.changePercent)

		stocksFlexTable.setText(row, 1, priceText)

		val changeWidget = stocksFlexTable.getWidget(row, 2) as Label
		changeWidget.text = changeText + " (" + changePercentText + "%)"
		changeWidget.styleName = [
			if (stockPrice.changePercent < -0.1f) {
				return STOCK_RESOURCES.stock.negativeChange
			}
			if (stockPrice.changePercent > 0.1f) {
				return STOCK_RESOURCES.stock.positiveChange
			}
			STOCK_RESOURCES.stock.noChange
		].apply(stockPrice)
	}

	def void addStock() {
		val symbol = newSymbolTextBox.text.toUpperCase.trim
		newSymbolTextBox.focus = true
		if (!symbol.matches("^[0-9A-Z\\.]{1,10}$")) {
			Window.alert(''''«symbol»' is not a valid symbol.''')
			newSymbolTextBox.selectAll
			return
		}
		newSymbolTextBox.text = ""

		if (stocks.contains(symbol)) {
			return
		}

		val row = stocksFlexTable.rowCount
		stocks.add(symbol)
		stocksFlexTable => [
			setText(row, 0, symbol)
			setWidget(row, 2, new Label)
			cellFormatter.addStyleName(row, 1, STOCK_RESOURCES.stock.watchListNumericColumn)
			cellFormatter.addStyleName(row, 2, STOCK_RESOURCES.stock.watchListNumericColumn)
			cellFormatter.addStyleName(row, 3, STOCK_RESOURCES.stock.watchListRemoveColumn)
			setWidget(row, 3,
				new Button("x") => [
					addStyleDependentName("remove")
					addClickHandler [
						val removedIndex = stocks.indexOf(symbol)
						stocks.remove(removedIndex)
						stocksFlexTable.removeRow(removedIndex + 1)
					]
				])
		]
	}

}
