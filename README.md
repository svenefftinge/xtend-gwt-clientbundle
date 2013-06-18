ClientBundle active annotation 
==============================

Why ClientBundle active annotation?
-----------------------------------
ClientBundle active annotation generates extensions of CssResource and ClientBundle interfaces for you which otherwise you have to create and support manually.

How to use ClientBundle active annotation?
------------------------------------------

### Creation of new ClientBundle
```java
@ImageResources("org/eclpise/xtend/gwt/stockwatcher/images")
@CssResource(value="stock", csses="org/eclpise/xtend/gwt/stockwatcher/css/StockWatcher.css")
@ClientBundle("/Users/kosyakov/Documents/workspaces/vaadin/xtend-gwt-clientbundle/stockwatcher/src/")
interface StockResources {
}
```
@ClientBundle - this annotation is used to declare an interface as ClientBundle. 
As value of the annotation you should type the path to the source folder.

@CssResource - this annotation is used to specify a css resource. 
As value you should type the alias of resource. Later you will use it to access this resource.
The attribute "csses" is an array of paths to css resources.

@ImageResources – this annotation is used to specify image resources.
As value you should type the path to the directory with images. All images from the directory will be added as resources.


### Example of generated code
```java
public interface StockResources extends com.google.gwt.resources.client.ClientBundle {

  // Xtend adds Util class into the interface which you can use to get an implementation
  @SuppressWarnings("all")
  public static class Util {
    private static StockResources INSTANCE;
    
    public static StockResources get() {
      if (INSTANCE == null) {
      	INSTANCE = com.google.gwt.core.client.GWT.create(StockResources.class);
      	// Util class takes care about injecting css resources
      	INSTANCE.stock().ensureInjected();
      }
      return INSTANCE;
    }
  }
  
  // Xtend generates an access method for css resources
  @Source(value = "org/eclpise/xtend/gwt/stockwatcher/css/StockWatcher.css")
  public abstract StockCssResource stock();
  
  // For every image from the image directory Xtend generates an access method 
  @Source(value = "org/eclpise/xtend/gwt/stockwatcher/images/blue_gradient.gif")
  public abstract ImageResource blue_gradientGif();
  
  @Source(value = "org/eclpise/xtend/gwt/stockwatcher/images/drafts.gif")
  public abstract ImageResource draftsGif();
  
  ...
}

public interface StockCssResource extends CssResource {

  //For every css class and def variable from css files Xtend generates an access method
  //Also Xtend takes care about resolving name conflicts between css classes and def variables
  @ClassName(value = "watchListHeader")
  public abstract String watchListHeader();
  
  @ClassName(value = "gwt-PushButton-up")
  public abstract String gwtPushButtonUp();
  
  @ClassName(value = "Caption")
  public abstract String caption();
...
```

### Access to resources
```java
// get the implementation of StockResources client bundle
val stockResources = StockResources.Util.get

// create an instance of Image class for googlecode.png picture
val image = new Image(stockResources.googlecodePng) 

// get an obfuscated name of watchListNumericColumn css class
val className = stockResources.stock.watchListNumericColumn 
```

If you want to compare Xtend version of StockWatcher with Java version you can find the second one here:
https://developers.google.com/web-toolkit/tools/gwtdesigner/tutorials/StockWatcher.zip



