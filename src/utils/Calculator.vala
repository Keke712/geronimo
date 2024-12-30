public class Calculator : Object {
    private static int get_precedence(string op) {
        switch (op) {
            case "+":
            case "-":
                return 1;
            case "*":
            case "/":
                return 2;
            case "^":
                return 3;
            default:
                return 0;
        }
    }

    private static bool is_operator(string token) {
        return token in "+-*/^";
    }

    private static List<string> tokenize(string expression) {
        var tokens = new List<string>();
        string number = "";
        
        for (int i = 0; i < expression.length; i++) {
            unichar c = expression[i];
            string c_str = c.to_string();
            
            if (c.isdigit() || c_str == ".") {
                number += c_str;
            } else if (is_operator(c_str) || c_str == "(" || c_str == ")") {
                if (number != "") {
                    tokens.append(number);
                    number = "";
                }
                tokens.append(c_str);
            } else if (c.isspace()) {
                if (number != "") {
                    tokens.append(number);
                    number = "";
                }
            }
        }
        
        if (number != "") {
            tokens.append(number);
        }
        
        return tokens;
    }

    private static double evaluate_operation(double a, double b, string op) throws CalculatorError {
        switch (op) {
            case "+":
                return a + b;
            case "-":
                return a - b;
            case "*":
                return a * b;
            case "/":
                if (b == 0) {
                    throw new CalculatorError.DIVISION_BY_ZERO("Division by zero");
                }
                return a / b;
            case "^":
                return Math.pow(a, b);
            default:
                throw new CalculatorError.INVALID_OPERATOR("Invalid operator: " + op);
        }
    }

    public static double evaluate(string expression) throws CalculatorError {
        if (expression.length == 0) {
            throw new CalculatorError.INVALID_EXPRESSION("Empty expression");
        }

        var tokens = tokenize(expression);
        var numbers = new List<string>();
        var operators = new List<string>();

        unowned List<string>? current = tokens;
        while (current != null) {
            string token = current.data;
            if (!is_operator(token) && token != "(" && token != ")") {
                numbers.prepend(token);
            } else if (token == "(") {
                operators.prepend(token);
            } else if (token == ")") {
                while (operators != null && operators.data != "(") {
                    if (numbers == null || numbers.next == null) {
                        throw new CalculatorError.INVALID_EXPRESSION("Invalid expression");
                    }

                    double b = double.parse(numbers.data);
                    numbers.remove_link(numbers);
                    double a = double.parse(numbers.data);
                    numbers.remove_link(numbers);
                    
                    string op = operators.data;
                    operators.remove_link(operators);
                    
                    numbers.prepend(evaluate_operation(a, b, op).to_string());
                }
                if (operators != null) {
                    operators.remove_link(operators); // Remove "("
                }
            } else {
                while (operators != null && 
                       operators.data != "(" && 
                       get_precedence(operators.data) >= get_precedence(token)) {
                    if (numbers == null || numbers.next == null) {
                        throw new CalculatorError.INVALID_EXPRESSION("Invalid expression");
                    }

                    double b = double.parse(numbers.data);
                    numbers.remove_link(numbers);
                    double a = double.parse(numbers.data);
                    numbers.remove_link(numbers);
                    
                    string op = operators.data;
                    operators.remove_link(operators);
                    
                    numbers.prepend(evaluate_operation(a, b, op).to_string());
                }
                operators.prepend(token);
            }
            current = current.next;
        }

        while (operators != null) {
            if (numbers == null || numbers.next == null) {
                throw new CalculatorError.INVALID_EXPRESSION("Invalid expression");
            }

            double b = double.parse(numbers.data);
            numbers.remove_link(numbers);
            double a = double.parse(numbers.data);
            numbers.remove_link(numbers);
            
            string op = operators.data;
            operators.remove_link(operators);
            
            numbers.prepend(evaluate_operation(a, b, op).to_string());
        }

        if (numbers == null) {
            throw new CalculatorError.INVALID_EXPRESSION("Invalid expression");
        }

        return double.parse(numbers.data);
    }
}

public errordomain CalculatorError {
    INVALID_OPERATOR,
    DIVISION_BY_ZERO,
    INVALID_EXPRESSION
}