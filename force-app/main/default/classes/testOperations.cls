@isTest
public class testOperations {
	@isTest
    public static void testAdd(){
        Integer sum = Operations.add(3,4);
        System.assertEquals(7,sum);
    }
    @isTest
    public static void testSubtract(){
        Integer subtract = Operations.subtract(4,3);
        System.assertEquals(1,subtract);
    }
}