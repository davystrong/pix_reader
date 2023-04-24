# Pix Reader

This project helps you use [Pix codes](https://www.bcb.gov.br/estabilidadefinanceira/pix) (a payment system based on [EMV QR codes](https://www.emvco.com/emv-technologies/qr-codes/)) as simple product labels. It consists of two parts: a generator, which can be used to quickly produce QR codes for specific values (as product labels); and a scanner, which sums multiple Pix codes and produces a total Pix code.

The app is available for download for Android and Mac, and should be easy to compile for Windows, Linux and iOS. It's also available as a [web app](https://davystrong.github.io/pix_reader), and should be installable as a PWA.

Please note that this project is licensed under the MIT licence. I make no guarantees that this works the way you expect it to. Make sure to test it well to ensure it works correctly in your specific use-case.

## Notes

There are some minor implementation details which may be relevant:
* When adding multiple Pix codes, the identifier, name, city etc. values of the first code are used for the total code. I.e. if you scan a code with a Pix ID of 1234 and another one with the Pix ID 5678, the Pix ID of the total code should be 1234, regardless of whether both codes actually point to the same account.
* I didn't actually implement the entire BR Code specification, much less the entire EMV specification. I implemented whatever seemed relevant. If you feel like improving this, feel free to submit a PR.
* The QR code scanner on the web app tends to be slower than the scanner on other platforms.