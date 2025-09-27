# EdgeSync Special Setup Guide

#### Recommended Steps:

1.  **Create a development directory** at the desired location.

2.  **Move the `EdgeSync` project folder** into this new directory.

3.  **Open the project** in your code editor from this new location.

4.  **Clean the project**: Before attempting to build again, run the following command in your terminal from the project's root directory:

    ```bash
    flutter clean
    ```

5.  **Install dependencies**: Install the required dependencies for the project by running:

    ```bash
    flutter pub get
    ```

6.  **Run the app**: You can now run the project without the path-related build error:

    ```bash
    flutter run
    ```

7.  **Create and enter a GROQ_API_JEY**: Go to https://console.groq.com/keys and create and enter the api key while running the harmonizer in the application.

---

**Note on Python Dependencies (`requirements.txt`)**: This project includes a `requirements.txt` file for Python packages. This is **only needed** if you plan to run the validation scripts located in the `test/` directory, which are used for analyzing the noise injection feature. It is **not required** for building or running the main Flutter application.
