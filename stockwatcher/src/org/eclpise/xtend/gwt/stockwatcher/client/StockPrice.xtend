package org.eclpise.xtend.gwt.stockwatcher.client

class StockPrice {
	@Property String symbol;
	@Property double price;
	@Property double change;

	new(String symbol, double price, double change) {
		this.symbol = symbol
		this.price = price
		this.change = change
	}

	def getChangePercent() {
		100.0 * change / price;
	}
}
